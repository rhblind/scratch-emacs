;;; modules/term/ghostel/config.el -*- lexical-binding: t; -*-
;;
;; Terminal emulator powered by libghostty-vt. Provides the same
;; surface as :term vterm: project-aware toggle popup at the bottom
;; 25 %, `SPC o t' / `SPC o T', workspace-aware buffer names, and
;; evil integration via the bundled evil-ghostel extension.

(declare-function ghostel--load-module "ghostel")
(declare-function ghostel--init-buffer "ghostel")
(declare-function ghostel--start-process "ghostel")
(declare-function safe-persp-name "persp-mode")
(declare-function get-current-persp "persp-mode")

(use-package ghostel
  :defer t
  :commands (ghostel ghostel-project)
  :init
  (setq ghostel-kill-buffer-on-exit t
        ghostel-max-scrollback (* 5 1024 1024))
  :config
  (when (modulep! :editor evil)
    (use-package evil-ghostel
      :after evil
      :hook (ghostel-mode . evil-ghostel-mode))))

;;;; Project-aware toggle / here

(defun scratch-ghostel--project-root ()
  "Return the current project root, or `default-directory' as fallback."
  (or (when-let ((proj (project-current))) (project-root proj))
      default-directory))

(defun scratch-ghostel--popup-buffer-name ()
  "Per-workspace popup buffer name."
  (format "*scratch:ghostel:%s*"
          (if (bound-and-true-p persp-mode)
              (safe-persp-name (get-current-persp))
            "main")))

(defun scratch/ghostel-toggle (&optional arg)
  "Toggle a ghostel popup at the project root.
With prefix ARG, kill the existing popup and spawn a fresh one."
  (interactive "P")
  (require 'ghostel)
  (let* ((default-directory (scratch-ghostel--project-root))
         (name (scratch-ghostel--popup-buffer-name))
         (buffer (get-buffer name))
         (window (and buffer (get-buffer-window buffer))))
    (cond
     (arg
      (when (buffer-live-p buffer)
        (let (confirm-kill-processes) (kill-buffer buffer)))
      (when (window-live-p window) (delete-window window))
      (scratch/ghostel-toggle nil))
     (window (delete-window window))
     ((buffer-live-p buffer) (pop-to-buffer buffer))
     (t (let ((buf (get-buffer-create name)))
          (with-current-buffer buf
            (unless (derived-mode-p 'ghostel-mode)
              (ghostel--load-module t)
              (ghostel--init-buffer buf)
              (ghostel--start-process)))
          (pop-to-buffer buf))))))

(defun scratch/ghostel-here (&optional arg)
  "Open ghostel in the current window at the project root.
With prefix ARG, open at `default-directory' instead."
  (interactive "P")
  (let ((default-directory (if arg default-directory
                             (scratch-ghostel--project-root))))
    (ghostel)))

;; Display rule: bottom 25 % side window, steal focus.
(add-to-list 'display-buffer-alist
             '("\\*scratch:ghostel:.*\\*"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.25)
               (post-command-select-window . t)))

;;;; Dismiss ghostel popup on workspace switch

(when (modulep! :ui workspaces)
  (with-eval-after-load 'persp-mode
    (defvar scratch-ghostel--workspace-visible (make-hash-table :test 'equal))

    (defun scratch-ghostel--side-window ()
      (cl-find-if
       (lambda (w)
         (and (window-parameter w 'window-side)
              (string-match-p "\\`\\*scratch:ghostel:.*\\*\\'"
                              (buffer-name (window-buffer w)))))
       (window-list)))

    (add-hook 'persp-before-switch-functions
              (lambda (&rest _)
                (let ((ws (scratch-workspaces--current-name))
                      (win (scratch-ghostel--side-window)))
                  (puthash ws (not (null win)) scratch-ghostel--workspace-visible)
                  (when win (delete-window win)))))

    (add-hook 'persp-activated-functions
              (lambda (&rest _)
                (when (gethash (scratch-workspaces--current-name)
                               scratch-ghostel--workspace-visible)
                  (let ((buf (get-buffer (scratch-ghostel--popup-buffer-name))))
                    (when (buffer-live-p buf)
                      (pop-to-buffer buf))))))))

;;;; Leader bindings under `SPC o' (open)

(when (modulep! :editor leader)
  (map! :leader
    (:prefix-map ("o" . "open")
     :desc "toggle terminal popup" "t" #'scratch/ghostel-toggle
     :desc "terminal here"         "T" #'scratch/ghostel-here)))
