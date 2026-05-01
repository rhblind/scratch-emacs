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
    ;; Override default `digit-argument' on M-N. Use C-u N for prefix args.
    (global-set-key (kbd (format "M-%d" n)) select-cmd)))

(provide 'scratch-window)
;;; scratch-window.el ends here
