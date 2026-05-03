;;; modules/checkers/syntax/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'flycheck)
(straight-use-package 'flycheck-posframe)

;; consult-flycheck: pair flycheck's error list with consult's picker
;; (richer preview, narrowing). Only installed when the consult ecosystem
;; is also enabled.
(when (modulep! :completion vertico)
  (straight-use-package 'consult-flycheck))
