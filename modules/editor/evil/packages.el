;;; modules/editor/evil/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'evil)
(straight-use-package 'evil-surround)
(straight-use-package 'evil-numbers)
(straight-use-package 'evil-nerd-commenter)
(straight-use-package 'evil-matchit)
(straight-use-package 'evil-args)
(straight-use-package 'avy)
;; TTY-only: send OSC 12 / DECSCUSR escape sequences to the terminal
;; so the cursor reflects the evil state. No-op in GUI frames (Emacs
;; renders the cursor itself there, evil sets it via `cursor-type').
(straight-use-package 'evil-terminal-cursor-changer)

(when (modulep! +everywhere)
  (straight-use-package 'evil-collection))
