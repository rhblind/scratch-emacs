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
   :desc "find from here"     "F" #'find-file-existing
   :desc "save buffer"        "s" #'save-buffer
   :desc "save as"            "S" #'write-file
   :desc "recent"             "r" #'recentf
   :desc "private config"     "p" #'scratch/find-file-in-user-config
   :desc "dired"              "d" #'dired
   :desc "locate"             "l" #'locate
   :desc "rename/move"        "R" #'scratch/rename-this-file
   :desc "copy file"          "C" #'scratch/copy-this-file
   :desc "delete file"        "D" #'scratch/delete-this-file
   :desc "sudo find file"     "u" #'scratch/sudo-find-file
   :desc "sudo this file"     "U" #'scratch/sudo-this-file
   :desc "yank path"          "y" #'scratch/yank-buffer-filepath
   :desc "yank relative path" "Y" #'scratch/yank-buffer-filepath-relative))
