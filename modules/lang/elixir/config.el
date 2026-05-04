;;; modules/lang/elixir/config.el -*- lexical-binding: t; -*-
;;
;; Elixir / Phoenix support. Built-in `elixir-ts-mode' (Emacs 30+, tree
;; -sitter-based) for `.ex' / `.exs', `heex-ts-mode' for `.heex'. LSP
;; via `dexter' (https://github.com/lexical-lsp/dexter or whichever
;; fork) -- expected on `$PATH', similar to csharp-ls.
;;
;; LSP: when `:tools lsp' is enabled, `elixir-ts-mode' is in
;; `scratch-lsp-auto-modes' by default, so `lsp-deferred' attaches on
;; file open. The dexter client we register below has higher priority
;; than lsp-mode's built-in `lsp-elixir' client, so it wins when both
;; are reachable.

;; Tell `:editor tree-sitter' that we want the elixir + heex grammars
;; managed by treesit-auto. Idempotent; no-op when tree-sitter isn't
;; enabled.
(add-to-list 'scratch-treesit-want 'elixir)
(add-to-list 'scratch-treesit-want 'heex)

;; Opt these modes into `:tools lsp' auto-attach. No-op when the lsp
;; module isn't enabled.
(when (modulep! :tools lsp)
  (dolist (mode '(elixir-ts-mode elixir-mode heex-ts-mode))
    (add-to-list 'scratch-lsp-auto-modes mode)))

;; Register grammar sources as a fallback for users without
;; `:editor tree-sitter' (treesit-auto otherwise provides these via
;; its recipe list). Lets `M-x treesit-install-language-grammar elixir'
;; / `... heex' work standalone.
(with-eval-after-load 'treesit
  (dolist (entry '((elixir "https://github.com/elixir-lang/tree-sitter-elixir")
                   (heex   "https://github.com/phoenixframework/tree-sitter-heex")))
    (add-to-list 'treesit-language-source-alist entry)))

;; `.heex' is a Phoenix template; route it to `heex-ts-mode' (Emacs
;; 30+; built-in, autoloaded). On older Emacs the symbol is unbound
;; and opening a `.heex' file would fall back to fundamental-mode --
;; harmless. `treesit-auto' would also register this when its auto
;; -mode-alist setup runs, but adding here keeps the module self-
;; contained for users without `:editor tree-sitter'.
(add-to-list 'auto-mode-alist '("\\.[hl]?eex\\'" . heex-ts-mode))

;; smartparens: wire `do .. end' as a pair, and `fn .. end'. Without
;; this the auto-pair-on-RET workflow is missing the most common
;; Elixir block. Doom uses the same patterns.
(with-eval-after-load 'smartparens
  (dolist (mode '(elixir-ts-mode elixir-mode heex-ts-mode))
    (sp-local-pair mode "do" "end"
                   :when '(("RET" "<evil-ret>"))
                   :unless '(sp-in-comment-p sp-in-string-p)
                   :post-handlers '("||\n[i]"))
    (sp-local-pair mode "do " " end" :unless '(sp-in-comment-p sp-in-string-p))
    (sp-local-pair mode "fn " " end" :unless '(sp-in-comment-p sp-in-string-p))))

;; LSP file-watching: Elixir / Phoenix projects accumulate large
;; directories under `_build', `deps', `.elixir_ls' etc. that should
;; never be watched. Drops the file count under `lsp-file-watch-
;; threshold' on real projects.
(with-eval-after-load 'lsp-mode
  (dolist (pat '("[/\\\\]_build\\'"           ; mix build artifacts
                 "[/\\\\]deps\\'"             ; fetched mix deps
                 "[/\\\\]\\.elixir_ls\\'"     ; elixir-ls cache
                 "[/\\\\]\\.expert\\'"        ; expert-ls cache
                 "[/\\\\]\\.lexical\\'"       ; lexical cache
                 "[/\\\\]priv[/\\\\]static\\'" ; phoenix compiled assets
                 "[/\\\\]cover\\'"))          ; ExCoveralls output
    (add-to-list 'lsp-file-watch-ignored-directories pat)))

;; Register `dexter' as an LSP client. Priority 2 wins over lsp-mode's
;; built-in `elixir-ls' client (priority -1). The connection resolves
;; `dexter' via `mise which dexter' rather than relying on `executable
;; -find' / PATH alone, because Emacs' PATH doesn't always include
;; mise's shim directory even when the user's shell does. `mise which'
;; returns the absolute path to whatever dexter version mise has active
;; for the current project, regardless of shim wiring.
;;
;; `:initialization-options' sends the per-project init params dexter
;; expects: follow delegate redirects (so go-to-definition works
;; through behaviour callbacks etc.) and debug logging off.
(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection
                     (lambda ()
                       (list (string-trim
                              (shell-command-to-string "mise which dexter"))
                             "lsp")))
    :major-modes '(elixir-mode elixir-ts-mode heex-ts-mode)
    :priority 2
    :server-id 'dexter-ls
    :initialization-options (lambda ()
                              (list :followDelegates t
                                    :debug nil))
    :notification-handlers (lsp-ht ("window/logMessage" #'ignore))
    :add-on? nil)))

;; Apheleia `mix-format' fallback. Used in buffers WITHOUT an LSP
;; server (`:editor format' prefers LSP `textDocument/formatting'
;; framework-wide; apheleia kicks in here for one-off `.exs' files
;; outside a mix project, or when dexter / elixir-ls failed to start).
;;
;; The override hardens apheleia's default mix-format: stdin via a
;; temp file (with `.ex' suffix so mix recognises the extension), `cd'
;; to project root, fully suppress stdout AND stderr during the mix
;; invocation (so a recompile that emits chatter doesn't corrupt the
;; formatted result), then `cat' the formatted temp file cleanly.
;; Exit code is preserved so apheleia notices real failures.
(with-eval-after-load 'apheleia
  (setf (alist-get 'mix-format apheleia-formatters)
        '("sh" "-c"
          "d=$(mktemp -d); t=\"$d/buf.ex\"; cat > \"$t\"; (cd $(git rev-parse --show-toplevel 2>/dev/null || pwd) && mix format \"$t\" >/dev/null 2>&1 && cat \"$t\"); rc=$?; rm -rf \"$d\"; exit $rc")))

;; Credo linting (CLI variant). Complements `lsp-credo' (the LSP
;; add-on bundled with lsp-mode): lsp-credo streams live diagnostics
;; while you type, flycheck-credo runs the full `credo' CLI on save
;; and catches things the LSP misses (project-wide rules, etc.).
;; Both run independently; flycheck shows them on the gutter.
(use-package flycheck-credo
  :when (modulep! :checkers syntax)
  :after flycheck
  :config (flycheck-credo-setup))

;; Dialyzer warnings via `flycheck-dialyxir'. flycheck only runs ONE
;; primary checker per buffer at a time -- in LSP buffers that's the
;; `lsp' checker. Chain dialyxir as a follow-up so its type-spec
;; findings layer on top of LSP / credo diagnostics.
;;
;; Note: lsp-mode defines the `lsp' flycheck checker LAZILY inside
;; `lsp-diagnostics-flycheck-enable' (when an LSP buffer activates),
;; not when `lsp-diagnostics' loads. So `flycheck-add-next-checker'
;; can't run at load time -- it must wait until the checker exists.
;; We advise-after `lsp-diagnostics-flycheck-enable' to register the
;; chain on first activation; the operation is idempotent so subsequent
;; calls are no-ops. dialyxir's own `:modes (elixir-mode elixir-ts-
;; mode)' predicate skips it in non-elixir buffers, so the chain is
;; safe globally.
(use-package flycheck-dialyxir
  :when (modulep! :checkers syntax)
  :after flycheck
  :config
  (flycheck-dialyxir-setup)
  (defun scratch-elixir--chain-dialyxir-after-lsp (&rest _)
    "Chain `elixir-dialyxir' after the `lsp' flycheck checker once both exist."
    (when (and (flycheck-valid-checker-p 'lsp)
               (flycheck-valid-checker-p 'elixir-dialyxir)
               (not (member '(t . elixir-dialyxir)
                            (flycheck-checker-get 'lsp 'next-checkers))))
      (flycheck-add-next-checker 'lsp '(t . elixir-dialyxir))))
  (with-eval-after-load 'lsp-diagnostics
    (advice-add 'lsp-diagnostics-flycheck-enable :after
                #'scratch-elixir--chain-dialyxir-after-lsp)))

;; `exunit': test-runner commands.
(use-package exunit
  :defer t
  :commands (exunit-mode exunit-verify-all exunit-rerun exunit-verify
             exunit-toggle-file-and-test exunit-toggle-file-and-test-other-window
             exunit-verify-single)
  :init
  (dolist (hook '(elixir-mode-hook elixir-ts-mode-hook))
    (add-hook hook #'exunit-mode)))

;; Localleader: `,' (or `M-,' in insert) inside elixir buffers. Both
;; `elixir-mode' and `elixir-ts-mode' get the same map. Defined as a
;; macro so `:map' takes a literal keymap (mirrors the csharp module).
(when (modulep! :editor leader)
  (defmacro scratch-elixir--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       ;; Test prefix (exunit).
       (:prefix-map ("t" . "test")
        :desc "verify all"            "a" #'exunit-verify-all
        :desc "rerun last"            "r" #'exunit-rerun
        :desc "verify file"           "v" #'exunit-verify
        :desc "verify single"         "s" #'exunit-verify-single
        :desc "toggle test (here)"    "T" #'exunit-toggle-file-and-test
        :desc "toggle test (other)"   "t" #'exunit-toggle-file-and-test-other-window)
       ;; Common LSP shortcuts that are nice to have at localleader.
       :desc "format buffer"         "=" #'lsp-format-buffer
       :desc "code action"           "a" #'lsp-execute-code-action
       :desc "rename"                "r" #'lsp-rename))

  (with-eval-after-load 'elixir-ts-mode
    (scratch-elixir--def-localleader elixir-ts-mode-map))
  (with-eval-after-load 'heex-ts-mode
    ;; heex-ts-mode-map exists only when the mode is loaded; bind same
    ;; subset (test bindings are useful in template files via `t T').
    (scratch-elixir--def-localleader heex-ts-mode-map)))
