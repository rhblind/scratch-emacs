;;; modules/lang/rust/config.el -*- lexical-binding: t; -*-
;;
;; Rust support. Built-in `rust-ts-mode' (Emacs 29+, tree-sitter-based)
;; for `.rs'; no legacy `rust-mode' / `rustic' fallback -- tree-sitter
;; only. LSP via lsp-mode's built-in `lsp-rust' client (rust-analyzer,
;; expected on PATH: `rustup component add rust-analyzer'). Syntax
;; checking via flycheck's built-in `rust-cargo' checker, or
;; `rust-clippy' with the `+clippy' flag.
;;
;; Two things this module adds beyond wiring:
;;
;; 1. rust-analyzer workspace discovery in polyglot projects. The
;;    server discovers workspaces from the lsp workspace folder, so a
;;    Cargo crate nested inside a non-Cargo project (Elixir umbrella
;;    with `native/cel_eval', for example) fails to start. Setting
;;    `lsp-rust-analyzer-linked-projects' to the nearest Cargo.toml
;;    fixes it; for workspace members cargo metadata still loads the
;;    whole workspace.
;;
;; 2. Binary-only crates in flycheck. `rust-cargo' defaults to
;;    `cargo ... --lib', which fails on crates without a library
;;    target ("no library targets found in package X", followed by
;;    flycheck's "Suspicious state" warning). Crates without
;;    `src/lib.rs' and without a `[lib]' section in Cargo.toml get the
;;    `--bin NAME' target instead.

;; Tell `:editor tree-sitter' that we want the rust grammar managed by
;; treesit-auto. Idempotent; no-op when tree-sitter isn't enabled.
(add-to-list 'scratch-treesit-want 'rust)

;; Grammar source as a fallback for users without `:editor tree-sitter'
;; (treesit-auto otherwise provides this via its recipe list). Lets
;; `M-x treesit-install-language-grammar RET rust' work standalone.
;; No rev pin: current tree-sitter-rust needs tree-sitter ABI 15,
;; which is what Emacs 30 ships.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(rust "https://github.com/tree-sitter/tree-sitter-rust")))

;;;; LSP (rust-analyzer)

(when (modulep! :tools lsp)
  ;; Opt `rust-ts-mode' into `:tools lsp' auto-attach; `lsp-deferred'
  ;; hooks it on entry.
  (add-to-list 'scratch-lsp-auto-modes 'rust-ts-mode)

  ;; Rust build artifacts; keeps the file watcher under
  ;; `lsp-file-watch-threshold' on real projects.
  (with-eval-after-load 'lsp-mode
    (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]target\\'"))

  (defun scratch-rust--cargo-manifest ()
    "Return the nearest Cargo.toml for the current buffer, or nil."
    (when buffer-file-name
      (when-let* ((dir (locate-dominating-file
                        (file-name-directory buffer-file-name)
                        "Cargo.toml")))
        (expand-file-name "Cargo.toml" dir))))

  (defun scratch-rust--linked-projects ()
    "Point rust-analyzer at the nearest Cargo.toml (buffer-local).
See the module header for why this is needed in polyglot projects.
Respects a user-provided global `lsp-rust-analyzer-linked-projects'."
    (when (and buffer-file-name
               (or (not (boundp 'lsp-rust-analyzer-linked-projects))
                   ;; NOTE: the defcustom default is `[]' and an empty
                   ;; vector is TRUTHY in Elisp, so `(not ...)' would
                   ;; never fire after lsp-rust.el has loaded -- the
                   ;; override would only ever apply to the first rust
                   ;; buffer of a session (while the variable was still
                   ;; unbound). `seq-empty-p' handles nil / empty
                   ;; vector alike.
                   (seq-empty-p (default-value 'lsp-rust-analyzer-linked-projects))))
      (when-let* ((manifest (scratch-rust--cargo-manifest)))
        (setq-local lsp-rust-analyzer-linked-projects (vector manifest)))))

  (add-hook 'rust-ts-mode-hook #'scratch-rust--linked-projects)

  ;; rust-analyzer settings, ported from the user's long-running Doom
  ;; setup: watch with clippy (so clippy lints stream in live), and
  ;; show inlay / chaining / closure-return-type hints. Override any
  ;; of these from your config.org if you disagree.
  (with-eval-after-load 'lsp-rust
    (setq lsp-eldoc-render-all t
          lsp-inlay-hint-enable t
          lsp-rust-analyzer-cargo-watch-command "clippy"
          lsp-rust-analyzer-display-chaining-hints t
          lsp-rust-analyzer-display-closure-return-type-hints t
          lsp-rust-analyzer-display-lifetime-elision-hints-enable
          "skip_trivial"
          lsp-rust-analyzer-display-parameter-hints nil
          ;; Must be one of "always" / "never" / "mutable" (string
          ;; choice in current lsp-mode): lsp-rust serializes the key
          ;; unconditionally, and `nil' becomes JSON `null', which
          ;; rust-analyzer's untagged enum rejects with "invalid
          ;; config value: /inlayHints/reborrowHints/enable" on every
          ;; connect. "never" disables the hints.
          lsp-rust-analyzer-display-reborrow-hints "never")))

;;;; Flycheck (cargo)

(defun scratch-rust--manifest-package-name (manifest)
  "Return the `name' value under [package] in Cargo.toml MANIFEST."
  (with-temp-buffer
    (insert-file-contents-literally manifest)
    (goto-char (point-min))
    (when (re-search-forward "^\\[package\\][ \t]*$" nil t)
      (let ((section-end
             (save-excursion
               (if (re-search-forward "^\\[" nil t)
                   (match-beginning 0)
                 (point-max)))))
        (save-restriction
          (narrow-to-region (point) section-end)
          (goto-char (point-min))
          (when (re-search-forward
                 "^[ \t]*name[ \t]*=[ \t]*\"\\([^\"]+\\)\"" nil t)
            (match-string 1)))))))

(defun scratch-rust--manifest-has-lib-p (manifest)
  "Whether the Cargo.toml MANIFEST declares a `[lib]' target."
  (with-temp-buffer
    (insert-file-contents-literally manifest)
    (goto-char (point-min))
    (re-search-forward "^\\[lib\\][ \t]*$" nil t)))

(defun scratch-rust--setup-flycheck ()
  "Configure flycheck's `rust-cargo' checker for the current buffer.
Binary-only crates (no `src/lib.rs', no `[lib]' section) check with
`cargo ... --bin NAME' instead of the default `--lib', which errors
out on them. See the module header."
  (when-let* ((manifest (scratch-rust--cargo-manifest)))
    (let ((crate-dir (file-name-directory manifest)))
      (unless (or (file-exists-p (expand-file-name "src/lib.rs" crate-dir))
                  (scratch-rust--manifest-has-lib-p manifest))
        (when-let* ((name (scratch-rust--manifest-package-name manifest)))
          (setq-local flycheck-rust-crate-type "bin")
          (setq-local flycheck-rust-binary-name name))))))

(when (modulep! :checkers syntax)
  (add-hook 'rust-ts-mode-hook #'scratch-rust--setup-flycheck))

;; +clippy: prefer flycheck's `rust-clippy' checker over `rust-cargo'.
;;
;; `flycheck-checkers' is a flat preference list and auto-selection runs
;; the first checker applicable to the buffer; the stock order puts
;; `rust-cargo' first (clippy is last of the three rust checkers).
;; Prepending `rust-clippy' makes it win while keeping the fallback: its
;; `:enabled' predicate requires the clippy component, so without one
;; auto-selection simply falls through to `rust-cargo'. Only rust
;; checkers match rust buffers, so hoisting clippy to the front of the
;; flat list cannot disturb other languages, and lsp-mode adds its `lsp'
;; checker with `add-to-list' (also a prepend), so an attached server
;; still outranks clippy. Unlike `rust-cargo', `rust-clippy' has a fixed
;; command line (plain `cargo clippy'), so the binary-only-crate vars
;; set by `scratch-rust--setup-flycheck' simply go unused there --
;; `cargo clippy' checks bin targets on its own.
(when (modulep! +clippy)
  (with-eval-after-load 'flycheck
    (setq flycheck-checkers
          (cons 'rust-clippy (delq 'rust-clippy flycheck-checkers)))))

;;;; Cargo commands

(defun scratch-rust--cargo-run (subcommand)
  "Run `cargo SUBCOMMAND' in the nearest Cargo project.
With a prefix arg, prompt for extra command line arguments."
  (if-let* ((manifest (scratch-rust--cargo-manifest)))
      (let* ((dir (file-name-directory manifest))
             (extra (when current-prefix-arg
                      (read-string (format "cargo %s args: " subcommand)))))
        (require 'compile)
        (let ((default-directory dir))
          (compilation-start
           (mapconcat #'identity (remq nil (list "cargo" subcommand extra))
                      " ")
           nil
           (lambda (_mode) (format "*cargo %s*" subcommand)))))
    (user-error "Not inside a Cargo project")))

(defun scratch/rust-cargo-build ()
  "Run `cargo build' for the current crate."
  (interactive)
  (scratch-rust--cargo-run "build"))

(defun scratch/rust-cargo-check ()
  "Run `cargo check' for the current crate."
  (interactive)
  (scratch-rust--cargo-run "check"))

(defun scratch/rust-cargo-clippy ()
  "Run `cargo clippy' for the current crate."
  (interactive)
  (scratch-rust--cargo-run "clippy"))

(defun scratch/rust-cargo-run ()
  "Run `cargo run' for the current crate."
  (interactive)
  (scratch-rust--cargo-run "run"))

(defun scratch/rust-cargo-test ()
  "Run `cargo test' for the current crate."
  (interactive)
  (scratch-rust--cargo-run "test"))

(defun scratch/rust-open-cargo-toml ()
  "Open the nearest Cargo.toml."
  (interactive)
  (if-let* ((manifest (scratch-rust--cargo-manifest)))
      (find-file manifest)
    (user-error "Not inside a Cargo project")))

(when (modulep! :editor leader)
  (with-eval-after-load 'rust-ts-mode
    (map! :map rust-ts-mode-map :localleader
          (:prefix-map ("b" . "cargo")
           :desc "cargo build"   "b" #'scratch/rust-cargo-build
           :desc "cargo check"   "c" #'scratch/rust-cargo-check
           :desc "cargo clippy"  "C" #'scratch/rust-cargo-clippy
           :desc "cargo run"     "r" #'scratch/rust-cargo-run
           :desc "open Cargo.toml" "o" #'scratch/rust-open-cargo-toml)
          (:prefix-map ("t" . "test")
           :desc "cargo test"    "a" #'scratch/rust-cargo-test)
          ;; LSP shortcuts that need an attached server; they error
          ;; cleanly ("no LSP workspace") when there isn't one.
          :desc "format buffer"  "=" #'lsp-format-buffer
          :desc "code action"    "a" #'lsp-execute-code-action
          :desc "rename"         "r" #'lsp-rename)))
