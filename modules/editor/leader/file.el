;;; modules/editor/leader/file.el -*- lexical-binding: t; -*-
;;
;; SPC f -- file-related leader bindings. Loaded by leader/config.el.

(map! :leader
  (:prefix-map ("f" . "file")
   :desc "find file"   "f" #'find-file
   :desc "save buffer" "s" #'save-buffer
   :desc "save all"    "S" #'save-some-buffers
   :desc "recent"      "r" #'recentf))
