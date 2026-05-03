;;; modules/term/vterm/config.el -*- lexical-binding: t; -*-
;;
;; Adapted from Doom's :term vterm, minus Doom-specific helpers. Provides:
;;
;;   - sensible defaults (5000 lines scrollback, kill on exit, no
;;     "process is running" prompt, no horizontal scroll margin),
;;   - `scratch/vterm-toggle' / `scratch/vterm-here' (project-aware,
;;     workspace-aware popup),
;;   - a side-panel `display-buffer-alist' entry so the popup lands at
;;     the bottom 25% of the frame and steals focus,
;;   - evil-aware `vterm-copy-mode' (motion state for navigation, back
;;     to insert state when copy-mode toggles off).

(use-package vterm
  :defer t
  :commands (vterm vterm-other-window
             scratch/vterm-toggle scratch/vterm-here)
  :init
  (setq vterm-kill-buffer-on-exit t
        vterm-max-scrollback 5000)
  ;; In batch / byte-compile, vterm's loader insists on building the
  ;; native module. Stub it out so byte-compiling our config doesn't
  ;; trigger a long C build (Doom's trick).
  (when noninteractive
    (advice-add 'vterm-module-compile :override #'ignore)
    (provide 'vterm-module))
  :config
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local confirm-kill-processes nil
                          hscroll-margin 0)))
  ;; `C-q' lets you send the next keypress through to the running
  ;; process literally (useful when an Emacs binding swallows it).
  (define-key vterm-mode-map (kbd "C-q") #'vterm-send-next-key)
  ;; Evil-aware copy-mode: the read-only browse state is motion (j/k
  ;; etc. work natively); leaving copy-mode drops back into insert so
  ;; typing in the shell resumes immediately.
  (when (modulep! :editor evil)
    (with-eval-after-load 'evil
      (add-hook 'vterm-copy-mode-hook
                (lambda ()
                  (if vterm-copy-mode
                      (evil-motion-state)
                    (evil-insert-state))))
      ;; Universal evil-vs-vterm fixes -- without these, evil + a shell
      ;; misbehaves regardless of taste.
      (map! :map vterm-mode-map
        ;; Shell tab completion (evil-collection sometimes intercepts).
        :i "TAB"           #'vterm-send-tab
        :i "<tab>"         #'vterm-send-tab
        ;; Delete-word-backward via M-/C-backspace (shells expect these).
        :i "M-<backspace>" #'vterm-send-meta-backspace
        :n "M-<backspace>" #'vterm-send-meta-backspace
        :i "C-<backspace>" #'vterm-send-meta-backspace
        :n "C-<backspace>" #'vterm-send-meta-backspace
        ;; Forward delete (the literal `<deletechar>' key code).
        "<deletechar>"     #'vterm-send-delete))))

;;;; Project-aware toggle / here

(defun scratch-vterm--project-root ()
  "Return the current project root, or `default-directory' as fallback."
  (or (when-let ((proj (project-current))) (project-root proj))
      default-directory))

(defun scratch-vterm--popup-buffer-name ()
  "Per-workspace popup buffer name (groups vterms by `:ui workspaces')."
  (format "*scratch:vterm:%s*"
          (if (bound-and-true-p persp-mode)
              (safe-persp-name (get-current-persp))
            "main")))

(defun scratch/vterm-toggle (&optional arg)
  "Toggle a vterm popup at the project root.
With prefix ARG, kill the existing popup and spawn a fresh one."
  (interactive "P")
  (require 'vterm)
  (let* ((default-directory (scratch-vterm--project-root))
         (name (scratch-vterm--popup-buffer-name))
         (buffer (get-buffer name))
         (window (and buffer (get-buffer-window buffer))))
    (cond
     ;; Force fresh: kill + relaunch.
     (arg
      (when (buffer-live-p buffer)
        (let (confirm-kill-processes) (kill-buffer buffer)))
      (when (window-live-p window) (delete-window window))
      (scratch/vterm-toggle nil))
     ;; Already visible -> hide.
     (window (delete-window window))
     ;; Hidden but alive -> show.
     ((buffer-live-p buffer) (pop-to-buffer buffer))
     ;; Create new.
     (t (let ((buf (get-buffer-create name)))
          (with-current-buffer buf
            (unless (eq major-mode 'vterm-mode) (vterm-mode)))
          (pop-to-buffer buf))))))

(defun scratch/vterm-here (&optional arg)
  "Open a vterm in the current window at the project root.
With prefix ARG, open it at `default-directory' instead."
  (interactive "P")
  (require 'vterm)
  (let ((default-directory (if arg default-directory
                             (scratch-vterm--project-root))))
    (vterm)))

;; Display rule for the toggle popup: bottom 25% side window, focus
;; selected so you can start typing immediately.
(add-to-list 'display-buffer-alist
             '("\\*scratch:vterm:.*\\*"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.25)
               (post-command-select-window . t)))

;;;; Leader bindings under `SPC o' (open)

(when (modulep! :editor leader)
  (map! :leader
    (:prefix-map ("o" . "open")
     :desc "toggle vterm popup" "t" #'scratch/vterm-toggle
     :desc "vterm here"         "T" #'scratch/vterm-here)))
