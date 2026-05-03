;;; modules/ui/default-text-scale/config.el -*- lexical-binding: t; -*-
;;
;; default-text-scale: zoom every buffer in lockstep by adjusting the
;; `default' face height. Complements (doesn't replace) Emacs's
;; per-buffer `text-scale-increase'. Cross-platform; on macOS our
;; `:os macos' module already binds `Cmd-=' / `Cmd--' / `Cmd-0' for
;; the per-buffer variant.
;;
;; Default bindings (after `default-text-scale-mode' activates):
;;   C-M-=  -- zoom in (all buffers)
;;   C-M--  -- zoom out
;;   C-M-0  -- reset

(use-package default-text-scale
  :hook (find-file . default-text-scale-mode)
  :commands (default-text-scale-mode
             default-text-scale-increase
             default-text-scale-decrease
             default-text-scale-reset))
