;;; modules/editor/leader/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; general is installed framework-wide in lisp/scratch-keys.el so the
;; `map!' macro is always available; this module just configures it.
(straight-use-package 'which-key)
