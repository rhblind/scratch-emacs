;;; modules/editor/leader/quit.el -*- lexical-binding: t; -*-
;;
;; SPC q -- quit/restart leader bindings. Loaded by leader/config.el.

(map! :leader
  "q"   '(:ignore t                  :which-key "quit")
  "q q" '(save-buffers-kill-terminal :which-key "quit Emacs")
  "q r" '(restart-emacs              :which-key "restart Emacs"))
