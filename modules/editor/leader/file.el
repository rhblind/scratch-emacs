;;; modules/editor/leader/file.el -*- lexical-binding: t; -*-
;;
;; SPC f -- file-related leader bindings. Loaded by leader/config.el.

(map! :leader
  "f"   '(:ignore t                :which-key "file")
  "f f" '(find-file                :which-key "find file")
  "f s" '(save-buffer              :which-key "save buffer")
  "f S" '(save-some-buffers        :which-key "save all")
  "f r" '(recentf                  :which-key "recent files"))
