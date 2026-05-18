;;; modules/editor/leader/quit.el -*- lexical-binding: t; -*-
;;
;; SPC q -- quit/restart leader bindings. Loaded by leader/config.el.

(defun scratch-quit-kill-daemon ()
  "Save buffers and kill Emacs, including the daemon process."
  (interactive)
  (save-some-buffers t)
  (kill-emacs))

(map! :leader
  (:prefix-map ("q" . "quit")
   :desc "quit Emacs"         "q" #'save-buffers-kill-terminal
   :desc "quit & kill daemon" "d" #'scratch-quit-kill-daemon
   :desc "restart Emacs"      "r" #'restart-emacs))
