;;; modules/lang/javascript/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; js-ts-mode, typescript-ts-mode, tsx-ts-mode ship built-in (Emacs 30+).

;; lsp-eslint ships bundled with lsp-mode; no separate package needed.

(straight-use-package 'jest)
