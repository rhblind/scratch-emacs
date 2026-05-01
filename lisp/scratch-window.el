;;; scratch-window.el --- window helpers -*- lexical-binding: t; -*-
;;
;; Native (winum-free) window numbering and buffer-to-window helpers,
;; ported from Spacemacs' originals via the user's Doom config.
;;
;; Window numbering uses `window-list' starting from `frame-first-window',
;; which gives a stable left-to-right, top-to-bottom enumeration.
;;
;; Defines:
;;   `scratch/select-window-by-number'      -- focus window N
;;   `scratch/move-buffer-to-window'        -- move current buffer to window N
;;   `scratch/swap-buffers-with-window'     -- swap current buffer with window N's
;;   `scratch/select-window-N'  (1..9)      -- focus shortcut, bound to `M-N' globally
;;   `scratch/buffer-to-window-N' (1..9)    -- move (no prefix) / swap (prefix arg)

(defun scratch-window--by-number (n)
  "Return the Nth window (1-based) of the current frame, or nil.
Numbering follows `window-list' order starting from `frame-first-window'."
  (when (and (integerp n) (> n 0))
    (nth (1- n) (window-list nil 'never (frame-first-window)))))

(defun scratch/select-window-by-number (n)
  "Select window N (1-based) in the current frame."
  (interactive "nWindow number: ")
  (let ((win (scratch-window--by-number n)))
    (if win
        (select-window win)
      (user-error "No window numbered %d" n))))

(defun scratch/move-buffer-to-window (n &optional follow)
  "Move the current buffer to window N (1-based) in the current frame.
If FOLLOW (or interactive prefix arg), select the destination window."
  (interactive "nWindow number: \nP")
  (let* ((cur-buf (current-buffer))
         (cur-win (selected-window))
         (dest    (scratch-window--by-number n)))
    (cond
     ((null dest)        (user-error "No window numbered %d" n))
     ((eq dest cur-win)  (message "Already in window %d" n))
     (t
      (set-window-buffer dest cur-buf)
      (switch-to-prev-buffer cur-win)
      (unrecord-window-buffer cur-win cur-buf)
      (when follow (select-window dest))))))

(defun scratch/swap-buffers-with-window (n &optional follow)
  "Swap the current buffer with the buffer shown in window N (1-based).
If FOLLOW (or interactive prefix arg), select window N after swapping."
  (interactive "nWindow number: \nP")
  (let* ((cur-buf  (current-buffer))
         (cur-win  (selected-window))
         (dest     (scratch-window--by-number n))
         (dest-buf (and dest (window-buffer dest))))
    (cond
     ((null dest)        (user-error "No window numbered %d" n))
     ((eq dest cur-win)  (message "Already in window %d" n))
     (t
      (set-window-buffer cur-win dest-buf)
      (set-window-buffer dest    cur-buf)
      (unrecord-window-buffer cur-win cur-buf)
      (unrecord-window-buffer dest    dest-buf)
      (when follow (select-window dest))))))

(defvar scratch-window--maximized-config nil
  "Saved window configuration for `scratch/toggle-maximize-window'.
Set when the user maximizes from a multi-window layout; cleared on
restore.")

(defun scratch/toggle-maximize-window ()
  "Toggle between fullscreen current window and the previous layout.

First call:  save the current window configuration and run
             `delete-other-windows'.
Second call: when only one window remains and a layout was saved,
             restore that saved configuration.

If you manually open a new split while maximized, the saved layout
becomes stale -- the next call re-saves the current state and
maximizes again."
  (interactive)
  (cond
   ((and scratch-window--maximized-config
         (= 1 (length (window-list nil 'never))))
    (set-window-configuration scratch-window--maximized-config)
    (setq scratch-window--maximized-config nil))
   (t
    (setq scratch-window--maximized-config (current-window-configuration))
    (delete-other-windows))))

;; Generate scratch/select-window-N and scratch/buffer-to-window-N for
;; N in 1..9, plus bind M-N globally to the select-window variant.
;; Lexical binding is required: the lambdas close over `n' from each
;; `let' iteration so the captured values stay distinct.
(dotimes (i 9)
  (let* ((n          (1+ i))
         (select-cmd (intern (format "scratch/select-window-%d" n)))
         (buffer-cmd (intern (format "scratch/buffer-to-window-%d" n))))
    (defalias select-cmd
      (lambda () (interactive) (scratch/select-window-by-number n))
      (format "Select window %d." n))
    (defalias buffer-cmd
      (lambda (&optional arg)
        (interactive "P")
        (if arg
            (scratch/swap-buffers-with-window n t)
          (scratch/move-buffer-to-window n t)))
      (format "Move current buffer to window %d. With prefix ARG, swap." n))
    ;; Bind M-N in general's override map AS state-aware bindings (via
    ;; `:states'). evil checks state-specific aux maps before regular
    ;; keymaps, so a binding only at the override-map root would lose to
    ;; e.g. evil-collection-magit-section's normal-state aux map. With
    ;; `:states' set, our binding lands in the override map's *intercept*
    ;; aux map for each state -- a level above evil-collection's regular
    ;; aux map -- which wins generically across all packages.
    (general-define-key
     :states '(normal visual motion emacs insert hybrid replace operator)
     :keymaps 'override
     (kbd (format "M-%d" n)) select-cmd)))

(provide 'scratch-window)
;;; scratch-window.el ends here
