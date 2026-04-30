;;; modules/emacs/vc/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'magit)

(when (modulep! +forge)
  (straight-use-package 'forge))
