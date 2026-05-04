;;; scratch-mouse.el --- mouse support across GUI and TTY -*- lexical-binding: t; -*-
;;
;; Mouse support that works in GUI Emacs (out of the box) and TTY
;; Emacs (via `xterm-mouse-mode'). The TTY side relies on the terminal
;; emulator speaking the SGR / 1006 mouse protocol -- iTerm2, kitty,
;; alacritty, foot, WezTerm, GNOME Terminal, modern xterm all do.
;; Older / minimal terminals fall through silently: clicks may work
;; but the mouse wheel won't.

;; `xterm-mouse-mode' is a global mode that hooks
;; `after-make-frame-functions'. Once enabled it activates for every
;; TTY frame (existing and future) and is a no-op on GUI frames, so
;; calling it once here covers daemon-spawned `emacsclient -t' too.
(xterm-mouse-mode 1)

;; Right-click context menu (Emacs 28+). GUI gets a popup, TTY gets
;; a `tmm'-style minibuffer menu. Major modes that ship a richer
;; menu (dired, magit, ...) override this on their own buffers.
(when (fboundp 'context-menu-mode)
  (context-menu-mode 1))

(setq mouse-yank-at-point             t   ; middle-click pastes at point, not at click
      mouse-wheel-tilt-scroll         t   ; horizontal wheel scrolls horizontally
      mouse-wheel-flip-direction      t   ; natural-scroll direction
      mouse-wheel-progressive-speed   nil ; fixed scroll per tick (don't accelerate)
      mouse-wheel-scroll-amount       '(2 ((shift)   . hscroll)
                                          ((control) . text-scale))
      mouse-wheel-scroll-amount-horizontal 2)

(provide 'scratch-mouse)
;;; scratch-mouse.el ends here
