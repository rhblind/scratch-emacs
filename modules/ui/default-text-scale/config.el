;;; modules/ui/default-text-scale/config.el -*- lexical-binding: t; -*-
;;
;; Zoom keybindings.  Defaults use Alt (Linux, Windows); `:os macos'
;; adds Cmd variants.  Base key = per-buffer, +Ctrl = all buffers.

(defun scratch-text-scale-reset ()
  "Reset both per-buffer and global text scale to default."
  (interactive)
  (text-scale-set 0)
  (when (and (fboundp 'default-text-scale-reset)
             (bound-and-true-p default-text-scale-mode))
    (default-text-scale-reset)))

(use-package default-text-scale
  :hook (find-file . default-text-scale-mode)
  :commands (default-text-scale-mode
             default-text-scale-increase
             default-text-scale-decrease
             default-text-scale-reset)
  :init
  (setq text-scale-mode-step 1.07)
  ;; Per-buffer: Alt =/-/0
  (global-set-key (kbd "M-=") #'text-scale-increase)
  (global-set-key (kbd "M--") #'text-scale-decrease)
  (global-set-key (kbd "M-0") #'scratch-text-scale-reset)
  ;; All buffers: Ctrl-Alt =/-/0
  (global-set-key (kbd "C-M-=") #'default-text-scale-increase)
  (global-set-key (kbd "C-M--") #'default-text-scale-decrease)
  (global-set-key (kbd "C-M-0") #'default-text-scale-reset))
