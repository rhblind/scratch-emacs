;;; modules/ui/smooth-scroll/config.el -*- lexical-binding: t; -*-
;;
;; Pixel-precise mouse-wheel / trackpad scrolling via [[https://github.com/jdtsmith/ultra-scroll][ultra-scroll]].
;; Adapted from Doom's :ui smooth-scroll, trimmed to the bits that match
;; the literate config most users (and the author) actually run.
;;
;; Requires Emacs 29+ (for `pixel-scroll-precision-mode'). On earlier
;; Emacs versions ultra-scroll silently no-ops via the `:when' guard.
;;
;; Flags:
;;   +interpolate -- add good-scroll for keyboard-triggered scrolling
;;                   (C-v / M-v / evil C-d / C-u). Off by default.

(use-package ultra-scroll
  :when (fboundp 'pixel-scroll-precision-mode)
  :hook (emacs-startup . ultra-scroll-mode)
  :init
  ;; ultra-scroll requires `scroll-margin' = 0 (greater values aren't
  ;; supported yet); pair with a small `scroll-conservatively' so point
  ;; doesn't jump to the middle of the screen on edge moves.
  (setq scroll-conservatively 3
        scroll-margin 0)
  :config
  ;; These minor modes are known to thrash repaint during a smooth scroll;
  ;; ultra-scroll briefly disables them while a scroll is in flight.
  (with-eval-after-load 'hl-todo
    (add-hook 'ultra-scroll-hide-functions #'hl-todo-mode))
  (with-eval-after-load 'diff-hl
    (add-hook 'ultra-scroll-hide-functions #'diff-hl-flydiff-mode))
  (add-hook 'ultra-scroll-hide-functions #'jit-lock-mode))

;;;; +interpolate -- good-scroll for keyboard-triggered scrolling

(when (modulep! +interpolate)
  (use-package good-scroll
    :hook (emacs-startup . good-scroll-mode)
    :config
    ;; ultra-scroll owns the mouse wheel; good-scroll only interpolates
    ;; keyboard-driven scrolls (C-v / M-v / evil C-d / C-u). When
    ;; good-scroll-mode flips on, restore the default mwheel functions
    ;; so ultra-scroll's wheel handling isn't intercepted.
    (defun scratch-smooth-scroll--coexist-h ()
      (when good-scroll-mode
        (setq mwheel-scroll-up-function   #'scroll-up
              mwheel-scroll-down-function #'scroll-down)))
    (add-hook 'good-scroll-mode-hook #'scratch-smooth-scroll--coexist-h)

    ;; Wire `scroll-up' / `scroll-down' through good-scroll's interpolation
    ;; when active, otherwise fall through to the originals.
    (defun scratch-smooth-scroll--line-to-step (line)
      (cond ((integerp line) (* line (line-pixel-height)))
            ((or (null line) (memq '- line))
             (- (good-scroll--window-usable-height)
                (* next-screen-context-lines (line-pixel-height))))
            ((line-pixel-height))))
    (defun scratch-smooth-scroll--scroll-up-a (orig &optional arg)
      (if good-scroll-mode
          (good-scroll-move (scratch-smooth-scroll--line-to-step arg))
        (funcall orig arg)))
    (defun scratch-smooth-scroll--scroll-down-a (orig &optional arg)
      (if good-scroll-mode
          (good-scroll-move (- (scratch-smooth-scroll--line-to-step arg)))
        (funcall orig arg)))
    (advice-add 'scroll-up   :around #'scratch-smooth-scroll--scroll-up-a)
    (advice-add 'scroll-down :around #'scratch-smooth-scroll--scroll-down-a)))
