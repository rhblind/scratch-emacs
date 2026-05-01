;;; scratch-buffer.el --- buffer helpers -*- lexical-binding: t; -*-
;;
;; Small interactive commands operating on the current buffer or the
;; buffer list. Bound under `SPC b' by the leader module.

(defun scratch/switch-to-last-buffer ()
  "Switch to the most recently visited buffer that isn't the current one."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

(defun scratch/scratch-buffer ()
  "Switch to the *scratch* buffer."
  (interactive)
  (switch-to-buffer (get-buffer-create "*scratch*")))

(defun scratch/new-empty-buffer ()
  "Create and switch to a new empty buffer."
  (interactive)
  (let ((buf (generate-new-buffer "*new*")))
    (switch-to-buffer buf)
    (setq buffer-offer-save t)))

(defun scratch/kill-other-buffers ()
  "Kill all buffers except the current one."
  (interactive)
  (let ((current (current-buffer))
        (count 0))
    (dolist (buf (buffer-list))
      (unless (eq buf current)
        (when (kill-buffer buf) (cl-incf count))))
    (message "Killed %d other buffer%s" count (if (= count 1) "" "s"))))

(defun scratch/kill-all-buffers ()
  "Kill every buffer (with confirmation)."
  (interactive)
  (when (yes-or-no-p "Kill all buffers? ")
    (let ((count 0))
      (dolist (buf (buffer-list))
        (when (kill-buffer buf) (cl-incf count)))
      (message "Killed %d buffer%s" count (if (= count 1) "" "s")))))

(defun scratch/copy-buffer-filepath ()
  "Copy the current buffer's file path to the kill ring as `path:line'.
With a prefix argument, copy just the path (no line number)."
  (interactive)
  (if-let ((path (buffer-file-name)))
      (let ((s (if current-prefix-arg
                   path
                 (format "%s:%d" path (line-number-at-pos)))))
        (kill-new s)
        (message "Copied: %s" s))
    (user-error "Buffer is not visiting a file")))

(defun scratch/replace-buffer-from-clipboard ()
  "Replace the entire buffer with the system clipboard contents."
  (interactive)
  (when (or (not (buffer-modified-p))
            (yes-or-no-p "Buffer modified -- replace contents anyway? "))
    (delete-region (point-min) (point-max))
    (clipboard-yank)
    (deactivate-mark)))

(provide 'scratch-buffer)
;;; scratch-buffer.el ends here
