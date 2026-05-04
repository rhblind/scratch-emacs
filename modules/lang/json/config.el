;;; modules/lang/json/config.el -*- lexical-binding: t; -*-
;;
;; JSON support. Built-in `json-ts-mode' (Emacs 29+, tree-sitter
;; -based) is preferred for `.json' / `.jsonc' / `.json5'; legacy
;; `js-json-mode' / `javascript-mode' is the fallback when the
;; grammar isn't yet installed.
;;
;; LSP attaches automatically via `scratch-lsp-auto-modes' (which
;; includes `json-ts-mode'). Install the server with:
;;   M-x lsp-install-server RET json-ls RET
;; or `npm i -g vscode-langservers-extracted'.
;;
;; Formatting: apheleia ships a default `prettier-json' formatter
;; for `json-mode' / `json-ts-mode'; nothing to do here.

;; Ask `:editor tree-sitter' to manage the json grammar (so
;; `M-x treesit-auto-install-all' covers it and the install prompt
;; fires when a `.json' file is opened without the grammar).
(add-to-list 'scratch-treesit-want 'json)

;; Grammar source for standalone use (`M-x treesit-install-language
;; -grammar RET json' without `:editor tree-sitter').
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(json "https://github.com/tree-sitter/tree-sitter-json"
                      "master" "src")))

;; Tree-sitter mode remap, only when the grammar is actually
;; installed -- otherwise legacy `js-json-mode' / `javascript-mode'
;; handle the buffer cleanly. Mirrors the csharp/elixir pattern.
(when (treesit-language-available-p 'json)
  (dolist (legacy '(js-json-mode javascript-mode))
    (add-to-list 'major-mode-remap-alist (cons legacy 'json-ts-mode))))

;; Opt these modes into `:tools lsp' auto-attach. No-op when the lsp
;; module isn't enabled.
(when (modulep! :tools lsp)
  (dolist (mode '(json-ts-mode js-json-mode))
    (add-to-list 'scratch-lsp-auto-modes mode)))
