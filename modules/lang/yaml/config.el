;;; modules/lang/yaml/config.el -*- lexical-binding: t; -*-
;;
;; YAML support. Built-in `yaml-ts-mode' (Emacs 29+, tree-sitter
;; -based) is preferred; legacy `yaml-mode' is the fallback when the
;; grammar isn't yet installed (covers `.yaml' / `.yml').
;;
;; LSP attaches automatically via `scratch-lsp-auto-modes' (which
;; includes `yaml-ts-mode'). Install the server with:
;;   M-x lsp-install-server RET yamlls RET
;; or `npm i -g yaml-language-server'.
;;
;; Formatting: apheleia ships a default `prettier-yaml' formatter for
;; `yaml-mode' / `yaml-ts-mode'; nothing to do here.

;; Ask `:editor tree-sitter' to manage the yaml grammar.
(add-to-list 'scratch-treesit-want 'yaml)

;; Grammar source for standalone use.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(yaml "https://github.com/ikatyang/tree-sitter-yaml")))

;; Tree-sitter mode remap, only when the grammar is installed.
;; Otherwise `yaml-mode' (the package above) handles `.yaml' / `.yml'
;; cleanly via its own auto-mode-alist entry.
(when (treesit-language-available-p 'yaml)
  (add-to-list 'major-mode-remap-alist '(yaml-mode . yaml-ts-mode)))

;; Opt these modes into `:tools lsp' auto-attach. No-op when the lsp
;; module isn't enabled.
(when (modulep! :tools lsp)
  (dolist (mode '(yaml-ts-mode yaml-mode))
    (add-to-list 'scratch-lsp-auto-modes mode)))
