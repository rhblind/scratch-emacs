;;; modules/os/macos/config.el -*- lexical-binding: t; -*-
;;
;; macOS-specific defaults. Only takes effect when running under
;; Darwin -- enabling the module on Linux / Windows is a no-op.

(when (eq system-type 'darwin)
  ;; UI: hide the macOS titlebar while keeping the rounded window corners
  ;;     and traffic-light controls (emacs-plus / emacs-mac 28+ feature).
  ;;     `default-frame-alist' covers future frames; `set-frame-parameter'
  ;;     covers the current one if a GUI frame already exists.
  (push '(undecorated-round . t) default-frame-alist)
  (when (display-graphic-p)
    (set-frame-parameter nil 'undecorated-round t))

  ;; UI: harmless extras even with `undecorated-round' on -- if a future
  ;;     change re-enables the titlebar these still apply.
  (setq ns-use-proxy-icon nil      ; hide the document/proxy icon
        frame-title-format nil)    ; no document name in titlebar

  ;; Behavior: don't open extra frames when the OS hands files to Emacs
  ;; (Finder open / `open -a Emacs.app foo.txt'); reuse the current one.
  (setq ns-pop-up-frames nil)

  ;; Modifier keys: Cmd -> Super, LEFT Option -> Meta, RIGHT Option ->
  ;; passthrough (native macOS character composition). The right
  ;; option lets Norwegian / German / etc. layouts type `|', `[]',
  ;; `{}' (right-Option-7, right-Option-8, etc.) without Emacs
  ;; swallowing it as a meta prefix. `mac-*' vars apply to the
  ;; emacs-mac build (Yamamoto), `ns-*' to emacs-plus / nextstep --
  ;; setting both is harmless when only one is recognised.
  (setq mac-command-modifier      'super
        ns-command-modifier       'super
        mac-option-modifier       'meta
        ns-option-modifier        'meta
        mac-right-option-modifier 'none
        ns-right-option-modifier  'none)

  ;; Keys: Cmd-= / Cmd-- / Cmd-0 for text-scale, matching macOS apps.
  ;; When `:ui default-text-scale' is enabled, hook into THAT (every
  ;; buffer in every frame zooms in lockstep -- much better than the
  ;; built-in per-buffer `text-scale-*'). Fall back to the per-buffer
  ;; variant when default-text-scale isn't loaded.
  (cond
   ((modulep! :ui default-text-scale)
    (global-set-key (kbd "s-=") #'default-text-scale-increase)
    (global-set-key (kbd "s--") #'default-text-scale-decrease)
    (global-set-key (kbd "s-0") #'default-text-scale-reset))
   (t
    (global-set-key (kbd "s-=") #'text-scale-increase)
    (global-set-key (kbd "s--") #'text-scale-decrease)
    (global-set-key (kbd "s-0") (lambda () (interactive) (text-scale-set 0))))))
