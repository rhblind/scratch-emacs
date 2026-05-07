;;; modules/editor/leader/file.el -*- lexical-binding: t; -*-
;;
;; SPC f -- file-related leader bindings. Loaded by leader/config.el.

(defun scratch/find-file-in-user-config ()
  "Open a file picker scoped to `scratch-user-dir'."
  (interactive)
  (let ((default-directory (file-name-as-directory scratch-user-dir)))
    (call-interactively #'find-file)))

(map! :leader
  (:prefix-map ("f" . "file")
   :desc "find file"          "f" #'find-file
   :desc "save buffer"        "s" #'save-buffer
   :desc "save all"           "S" #'save-some-buffers
   :desc "recent"             "r" #'recentf
   :desc "private config"     "p" #'scratch/find-file-in-user-config))
