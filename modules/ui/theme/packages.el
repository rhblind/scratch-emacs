;;; modules/ui/theme/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; modus-operandi / modus-vivendi are built-in to Emacs 28+, so the
;; default theme stack needs no install. Only auto-dark gets pulled in,
;; and only for the default behavior (follow-OS).

(unless (or (modulep! +light) (modulep! +dark))
  (straight-use-package 'auto-dark))
