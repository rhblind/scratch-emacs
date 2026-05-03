;;; modules/editor/evil/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'evil)
(straight-use-package 'evil-surround)
(straight-use-package 'evil-numbers)
(straight-use-package 'evil-nerd-commenter)
(straight-use-package 'evil-matchit)
(straight-use-package 'evil-args)
(straight-use-package 'avy)

(when (modulep! +everywhere)
  (straight-use-package 'evil-collection))
