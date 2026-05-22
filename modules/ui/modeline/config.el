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
  ;; Auto-disable icons in TTY frames; show them on GUI. Mirrors the
  ;; setting from your existing Doom config.
  (setq doom-modeline-icon              (display-graphic-p)
        doom-modeline-major-mode-icon   t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-env-version       nil)   ; lang-version segment is too noisy
  :config
  (column-number-mode 1)
  (doom-modeline-mode 1)

  ;; Upstream bug: `doom-modeline--evil' calls `(funcall tag)' where
  ;; tag can be nil for evil states without a :tag property (e.g.
  ;; magit transient states). The .elc for this file is deleted so
  ;; the defsubst is not inlined and advice works.
  (defun scratch-modeline--safe-evil-tag (fn)
    (condition-case nil (funcall fn)
      (void-function nil)))
  (advice-add #'doom-modeline--evil :around #'scratch-modeline--safe-evil-tag)

  ;; Modified-buffer indicator: italic, with the foreground left to the
  ;; theme's `doom-modeline-buffer-modified' default (modus-themes pick a
  ;; high-contrast warning hue automatically).
  (set-face-attribute 'doom-modeline-buffer-modified nil :slant 'italic)

  ;; Override doom-modeline's `window-number' segment (which expects winum)
  ;; with one based on our native numbering from `lisp/scratch-window.el'.
  ;; Only render when there are multiple windows; matches the doom-modeline
  ;; built-in's behavior visually.
  (require 'cl-lib)
  (doom-modeline-def-segment window-number
    "Window number based on `scratch-window--numbered-list' (native, no winum)."
    (let* ((wins (scratch-window--numbered-list))
           (idx  (cl-position (selected-window) wins)))
      (when (and idx (> (length wins) 1))
        (propertize (format " %d " (1+ idx))
                    'face (if (doom-modeline--active)
                              'doom-modeline-buffer-major-mode
                            'mode-line-inactive)))))

  ;; Refresh doom-modeline on theme change. doom-modeline caches its bar
  ;; pixmap and various propertized segment strings, so a plain
  ;; `load-theme' alone won't repaint everything. Toggling the mode off
  ;; and back on rebuilds all of it cleanly. `enable-theme-functions'
  ;; (Emacs 29+) fires on every successful `load-theme'/`enable-theme'.
  (defun scratch-modeline--refresh-on-theme-change (&rest _)
    (when (bound-and-true-p doom-modeline-mode)
      (doom-modeline-mode -1)
      (doom-modeline-mode 1)
      (force-mode-line-update t)))
  (when (boundp 'enable-theme-functions)
    (add-hook 'enable-theme-functions
              #'scratch-modeline--refresh-on-theme-change))
  ;; auto-dark fires its own hooks when the OS appearance flips; cover
  ;; that path too so +auto theme switches are caught.
  (with-eval-after-load 'auto-dark
    (add-hook 'auto-dark-dark-mode-hook
              #'scratch-modeline--refresh-on-theme-change)
    (add-hook 'auto-dark-light-mode-hook
              #'scratch-modeline--refresh-on-theme-change)))
