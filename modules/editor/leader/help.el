;;; modules/editor/leader/help.el -*- lexical-binding: t; -*-
;;
;; SPC h -- help / describe-* leader bindings. Loaded by leader/config.el.

(map! :leader
  (:prefix-map ("h" . "help")
   :desc "describe function" "f" #'describe-function
   :desc "describe variable" "v" #'describe-variable
   :desc "describe key"      "k" #'describe-key
   :desc "describe mode"     "m" #'describe-mode))
