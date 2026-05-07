;;; modules/tools/just/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/leon-barrett/just-mode.el][just-mode]]: major mode for editing Justfiles, the task files for
;; the [[https://github.com/casey/just][just]] command runner. Provides syntax highlighting, indentation,
;; and comment handling.
;;
;; When paired with :tools lsp, lsp-mode's built-in just client
;; (lsp-just) attaches automatically via scratch-lsp-auto-modes.

(use-package just-mode
  :defer t)

(when (modulep! :tools lsp)
  (add-to-list 'scratch-lsp-auto-modes 'just-mode))
