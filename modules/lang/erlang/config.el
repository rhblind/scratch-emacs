;;; modules/lang/erlang/config.el -*- lexical-binding: t; -*-
;;
;; Erlang support. `erlang-ts-mode' (tree-sitter-based, derives from
;; `erlang-mode') for .erl / .hrl / .xrl / .yrl / .app.src /
;; .escript. LSP via ELP (lsp-mode's built-in client), erlfmt for
;; fallback formatting via apheleia.

;; Tell `:editor tree-sitter' that we want the erlang grammar managed
;; by treesit-auto. No-op when tree-sitter isn't enabled.
(add-to-list 'scratch-treesit-want 'erlang)

;; Register grammar source as a fallback for users without
;; `:editor tree-sitter'. Lets `M-x treesit-install-language-grammar
;; erlang' work standalone.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(erlang "https://github.com/WhatsApp/tree-sitter-erlang")))

;; Remap `erlang-mode' to `erlang-ts-mode' when the grammar is
;; available. Without the guard, `erlang-ts-mode' would fail with a
;; dlopen warning (the .so doesn't exist), leaving a broken buffer.
;; With the guard, missing-grammar machines fall back to plain
;; `erlang-mode'.
(when (treesit-language-available-p 'erlang)
  (add-to-list 'major-mode-remap-alist '(erlang-mode . erlang-ts-mode)))

(defun scratch-erlang-install-grammar ()
  "Install the erlang tree-sitter grammar and switch to `erlang-ts-mode'.
Builds the grammar from upstream source (registered above in
`treesit-language-source-alist') and reverts the current buffer if
it's an Erlang file so it picks up the tree-sitter mode immediately."
  (interactive)
  (treesit-install-language-grammar 'erlang)
  (add-to-list 'major-mode-remap-alist '(erlang-mode . erlang-ts-mode))
  (when (and buffer-file-name
             (string-match-p "\\.\\(erl\\|hrl\\|xrl\\|yrl\\)\\'" buffer-file-name))
    (revert-buffer nil t)))

(defvar scratch-erlang--grammar-prompted nil
  "Set once we've asked the user about installing the Erlang grammar this session.")

(defvar scratch-erlang--tree-sitter-module-p (modulep! :editor tree-sitter)
  "Non-nil when `:editor tree-sitter' is enabled. Captured at load time.")

(defun scratch-erlang--maybe-prompt-grammar-install ()
  "Offer (once) to install the erlang grammar on first `.erl' open.
Fallback path for users WITHOUT `:editor tree-sitter' -- when that
module is enabled, treesit-auto's own install prompt covers this
case. Idempotent: only prompts the first time `erlang-mode'
activates with a missing grammar."
  (when (and (not scratch-erlang--grammar-prompted)
             (not scratch-erlang--tree-sitter-module-p)
             (eq major-mode 'erlang-mode)
             (not (treesit-language-available-p 'erlang)))
    (setq scratch-erlang--grammar-prompted t)
    (when (y-or-n-p "Install the Erlang tree-sitter grammar (better highlighting, structural editing, LSP)? ")
      (scratch-erlang-install-grammar))))

(add-hook 'erlang-mode-hook #'scratch-erlang--maybe-prompt-grammar-install)

;; Opt these modes into `:tools lsp' auto-attach. No-op when the lsp
;; module isn't enabled.
(when (modulep! :tools lsp)
  (dolist (mode '(erlang-ts-mode erlang-mode))
    (add-to-list 'scratch-lsp-auto-modes mode)))

;; Select ELP as the active Erlang LSP server. lsp-mode ships both
;; `erlang-ls' and `erlang-language-platform' (ELP) clients; the
;; server with higher priority wins. `lsp-erlang-server' controls
;; which one gets priority 1 vs -2.
(with-eval-after-load 'lsp-erlang
  (setq lsp-erlang-server 'erlang-language-platform))

;; LSP file-watching: Erlang projects accumulate large directories
;; under `_build', `_checkouts', `.elp' that should never be watched.
(with-eval-after-load 'lsp-mode
  (dolist (pat '("[/\\\\]_build\\'"       ; rebar3 / mix build artifacts
                "[/\\\\]_checkouts\\'"    ; rebar3 local dependency checkouts
                "[/\\\\]\\.elp\\'"))      ; ELP cache directory
    (add-to-list 'lsp-file-watch-ignored-directories pat)))

;; Apheleia `erlfmt' fallback. Used in buffers WITHOUT an LSP server
;; that supports formatting (ELP does not currently implement
;; textDocument/formatting). Reads stdin, writes stdout.
(with-eval-after-load 'apheleia
  (setf (alist-get 'erlfmt apheleia-formatters)
        '("erlfmt" "-"))
  (dolist (mode '(erlang-mode erlang-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) '(erlfmt))))

;; Localleader: `,` (or `M-,' in insert) inside erlang buffers.
;; Both `erlang-mode' and `erlang-ts-mode' get the same map. Only
;; erlang-specific commands that aren't covered by the standard
;; `SPC c' LSP menu.
(when (modulep! :editor leader)
  (defmacro scratch-erlang--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       :desc "erlang shell"    "s" #'erlang-shell-display
       :desc "compile"         "c" #'erlang-compile
       :desc "next error"      "e" #'erlang-next-error))

  (with-eval-after-load 'erlang
    (scratch-erlang--def-localleader erlang-mode-map))
  (with-eval-after-load 'erlang-ts
    (scratch-erlang--def-localleader erlang-ts-mode-map)))
