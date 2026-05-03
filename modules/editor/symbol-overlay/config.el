;;; modules/editor/symbol-overlay/config.el -*- lexical-binding: t; -*-
;;
;; symbol-overlay: highlight every occurrence of the symbol at point
;; with an overlay; jump between them. Auto-enabled in `prog-mode'.
;;
;; Default keys (active when `symbol-overlay-mode' is on, i.e. inside
;; prog buffers):
;;   M-i  -- toggle overlay on the symbol at point (`symbol-overlay-put')
;;   M-n  -- jump to next overlay  (`symbol-overlay-jump-next')
;;   M-p  -- jump to previous      (`symbol-overlay-jump-prev')
;;   M-N / M-P -- next / prev definition
;;
;; (`M-i' in stock Emacs is `tab-to-tab-stop' which most users never
;; reach for; symbol-overlay rebinds it to its more useful action.
;; If you actually use `tab-to-tab-stop', override in your config.)

(use-package symbol-overlay
  :hook (prog-mode . symbol-overlay-mode)
  :commands (symbol-overlay-put
             symbol-overlay-jump-next
             symbol-overlay-jump-prev
             symbol-overlay-remove-all))
