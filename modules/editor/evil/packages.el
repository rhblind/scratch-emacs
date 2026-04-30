;;; modules/editor/evil/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'evil)

(when (modulep! +everywhere)
  (straight-use-package 'evil-collection))
