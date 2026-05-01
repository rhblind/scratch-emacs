;;; modules/editor/leader/quit.el -*- lexical-binding: t; -*-
;;
;; SPC q -- quit/restart leader bindings. Loaded by leader/config.el.

(map! :leader
  (:prefix-map ("q" . "quit")
   :desc "quit Emacs"    "q" #'save-buffers-kill-terminal
   :desc "restart Emacs" "r" #'restart-emacs))
