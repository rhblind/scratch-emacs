;;; scratch-file.el --- file operation helpers -*- lexical-binding: t; -*-
;;
;; Interactive commands for operating on the current buffer's file:
;; rename/move, copy, delete, sudo edit, yank path. Bound under
;; `SPC f' by the leader module.

(defun scratch/rename-this-file ()
  "Rename or move the current file and its buffer."
  (interactive)
  (let ((old (or (buffer-file-name)
                 (user-error "Buffer is not visiting a file"))))
    (let ((new (read-file-name "Rename/move to: " nil nil nil
                               (file-name-nondirectory old))))
      (when (file-directory-p new)
        (setq new (expand-file-name (file-name-nondirectory old) new)))
      (make-directory (file-name-directory new) t)
      (rename-file old new 1)
      (set-visited-file-name new t t)
      (message "Renamed to %s" (abbreviate-file-name new)))))

(defun scratch/copy-this-file ()
  "Copy the current file to a new location and open the copy."
  (interactive)
  (let ((old (or (buffer-file-name)
                 (user-error "Buffer is not visiting a file"))))
    (let ((new (read-file-name "Copy to: " nil nil nil
                               (file-name-nondirectory old))))
      (when (file-directory-p new)
        (setq new (expand-file-name (file-name-nondirectory old) new)))
      (make-directory (file-name-directory new) t)
      (copy-file old new 1)
      (find-file new)
      (message "Copied to %s" (abbreviate-file-name new)))))

(defun scratch/delete-this-file ()
  "Delete the current file and kill its buffer."
  (interactive)
  (let ((file (or (buffer-file-name)
                  (user-error "Buffer is not visiting a file"))))
    (when (yes-or-no-p (format "Delete %s? " (abbreviate-file-name file)))
      (if (vc-backend file)
          (vc-delete-file file)
        (delete-file file t)
        (kill-buffer)))))

(defun scratch/sudo-find-file ()
  "Open a file as root via TRAMP sudo."
  (interactive)
  (let ((file (read-file-name "Sudo find file: ")))
    (find-file (concat "/sudo::" (expand-file-name file)))))

(defun scratch/sudo-this-file ()
  "Reopen the current file as root via TRAMP sudo."
  (interactive)
  (let ((file (or (buffer-file-name)
                  (user-error "Buffer is not visiting a file")))
        (pos (point)))
    (find-file (concat "/sudo::" file))
    (goto-char pos)))

(defun scratch/yank-buffer-filepath ()
  "Copy the current buffer's absolute file path to the kill ring."
  (interactive)
  (if-let ((path (buffer-file-name)))
      (progn
        (kill-new path)
        (message "Copied: %s" path))
    (user-error "Buffer is not visiting a file")))

(defun scratch/yank-buffer-filepath-relative ()
  "Copy the current buffer's project-relative file path to the kill ring.
Falls back to the absolute path when outside a project."
  (interactive)
  (if-let ((path (buffer-file-name)))
      (let* ((proj (project-current))
             (root (when proj (project-root proj)))
             (rel (if root
                      (file-relative-name path root)
                    path)))
        (kill-new rel)
        (message "Copied: %s" rel))
    (user-error "Buffer is not visiting a file")))

(provide 'scratch-file)
;;; scratch-file.el ends here
