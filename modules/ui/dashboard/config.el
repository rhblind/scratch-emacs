;;; modules/ui/dashboard/config.el -*- lexical-binding: t; -*-

(defvar scratch-dashboard--dir
  (file-name-directory (or load-file-name buffer-file-name)))

(defvar scratch-dashboard-banner-template
  (expand-file-name "gnu-template.svg" scratch-dashboard--dir))

(defvar scratch-dashboard-banner-height 250)

(defvar scratch-dashboard-template-colours
  '(("$colour1" . font-lock-keyword-face)
    ("$colour2" . default))
  "Color substitutions for the banner template.
Each entry is (PLACEHOLDER . FACE-OR-SYMBOL).
For `default', the face background is used; for all others, the
face foreground.")

(defun scratch-dashboard--insert-banner ()
  "Insert a themed SVG banner (GUI) or nothing (TTY)."
  (goto-char (point-max))
  (insert "\n")
  (when (display-graphic-p)
    (condition-case err
        (let* ((svg-data (with-temp-buffer
                           (insert-file-contents scratch-dashboard-banner-template)
                           (goto-char (point-min))
                           (when (search-forward "$height" nil t)
                             (replace-match
                              (number-to-string scratch-dashboard-banner-height) nil t))
                           (dolist (sub scratch-dashboard-template-colours)
                             (goto-char (point-min))
                             (let ((color (if (eq (cdr sub) 'default)
                                             (or (face-background 'default nil t)
                                                 "#282c34")
                                           (or (face-foreground (cdr sub) nil t)
                                               "#81a2be"))))
                               (while (search-forward (car sub) nil t)
                                 (replace-match color nil t))))
                           (buffer-string)))
               (image (create-image svg-data 'svg t))
               (start (point)))
          (insert "\n")
          (insert-image image "GNU")
          (insert "\n")
          (when-let* ((align `(space . (:align-to (- center (0.5 . ,image)))))
                      (prefix (propertize " " 'display align)))
            (add-text-properties start (point)
                                 `(line-prefix ,prefix wrap-prefix ,prefix
                                   cursor-intangible t inhibit-isearch t))))
      (error (message "[scratch] Dashboard banner error: %S" err)))))

(use-package dashboard
  :demand t
  :init
  (setq dashboard-items '((recents . 8)
                          (projects . 5))
        dashboard-set-navigator nil
        dashboard-set-footer nil
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-startup-banner 'logo
        dashboard-banner-logo-title nil)
  :config
  (setq dashboard-startupify-list
        (cl-substitute #'scratch-dashboard--insert-banner
                       'dashboard-insert-banner
                       (cl-remove 'dashboard-insert-banner-title
                                  (cl-remove 'dashboard-insert-init-info
                                             dashboard-startupify-list))))
  (if (daemonp)
      (add-hook 'server-after-make-frame-hook
                (defun scratch-dashboard--init-on-frame ()
                  (add-hook 'window-size-change-functions
                            #'dashboard-resize-on-hook 100)
                  (dashboard-open)
                  (remove-hook 'server-after-make-frame-hook
                               #'scratch-dashboard--init-on-frame)))
    (dashboard-setup-startup-hook))
  (add-hook 'enable-theme-functions
            (lambda (&rest _)
              (when (and (display-graphic-p)
                         (get-buffer dashboard-buffer-name))
                (save-window-excursion
                  (dashboard-open))))))
