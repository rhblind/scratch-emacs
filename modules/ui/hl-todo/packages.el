;;; modules/ui/hl-todo/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'hl-todo)

;; consult-todo: project-wide TODO / FIXME / NOTE picker via consult.
;; Only installed when the consult ecosystem is also enabled.
(when (modulep! :completion vertico)
  (straight-use-package 'consult-todo))
