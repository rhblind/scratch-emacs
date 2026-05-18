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
             symbol-overlay-rename
             symbol-overlay-remove-all)
  :config
  (defun scratch-symbol-overlay/--promote-symbol ()
    "Set the symbol at point as the evil search pattern without moving.
Direction is always set to forward so `evil-ex-search-next' goes
forward and `evil-ex-search-previous' goes backward."
    (when-let* ((sym (thing-at-point 'symbol t)))
      (let ((regex (format "\\_<%s\\_>" (regexp-quote sym))))
        (setq evil-ex-search-pattern (evil-ex-make-search-pattern regex)
              evil-ex-search-direction 'forward)
        (evil-ex-search-activate-highlight evil-ex-search-pattern)
        t)))

  (defun scratch-symbol-overlay/search-next ()
    "Promote symbol at point to evil search, or repeat the last search.
When evil search highlights are inactive and point is on a symbol,
promotes it and jumps forward. Otherwise repeats the last search."
    (interactive)
    (when (and (bound-and-true-p symbol-overlay-mode)
               (not (evil-ex-hl-active-p 'evil-ex-search))
               (thing-at-point 'symbol))
      (scratch-symbol-overlay/--promote-symbol))
    (evil-ex-search-next 1))

  (defun scratch-symbol-overlay/search-prev ()
    "Promote symbol at point to evil search, or repeat the last search.
When evil search highlights are inactive and point is on a symbol,
promotes it and jumps backward. Otherwise repeats the last search."
    (interactive)
    (when (and (bound-and-true-p symbol-overlay-mode)
               (not (evil-ex-hl-active-p 'evil-ex-search))
               (thing-at-point 'symbol))
      (scratch-symbol-overlay/--promote-symbol))
    (evil-ex-search-previous 1))

  (evil-define-key 'normal symbol-overlay-mode-map
    "n" #'scratch-symbol-overlay/search-next
    "N" #'scratch-symbol-overlay/search-prev))
