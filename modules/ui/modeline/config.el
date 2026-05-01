;;; modules/ui/modeline/config.el -*- lexical-binding: t; -*-
;;
;; doom-modeline -- the polished, icon-rich modeline familiar from Doom
;; Emacs. Pairs naturally with nano-theme.
;;
;; Icons require nerd-fonts. If you see boxes / question marks instead of
;; glyphs, run `M-x nerd-icons-install-fonts' once on this machine.

(use-package nerd-icons
  :demand t)

(use-package doom-modeline
  :demand t
  :init
  ;; Auto-disable icons in TTY frames; show them on GUI. Mirror's the
  ;; setting from your existing Doom config.
  (setq doom-modeline-icon              (display-graphic-p)
        doom-modeline-major-mode-icon   t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-env-version       nil)   ; the lang-version part is too noisy
  :config
  (doom-modeline-mode 1))
