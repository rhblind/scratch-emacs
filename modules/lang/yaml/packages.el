;;; modules/lang/yaml/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; `yaml-ts-mode' (tree-sitter) ships built-in to Emacs 29+. We pull
;; the legacy `yaml-mode' (yoshiki/yaml-mode) anyway so files open
;; cleanly even when the tree-sitter grammar isn't yet installed.
;; LSP via `yaml-language-server' (install with `M-x lsp-install-
;; server yamlls' or `npm i -g yaml-language-server').
(straight-use-package 'yaml-mode)
