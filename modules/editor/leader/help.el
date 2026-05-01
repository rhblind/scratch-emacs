;;; modules/editor/leader/help.el -*- lexical-binding: t; -*-
;;
;; SPC h -- help / describe-* leader bindings. Loaded by leader/config.el.

(map! :leader
  "h"   '(:ignore t                :which-key "help")
  "h f" '(describe-function        :which-key "describe function")
  "h v" '(describe-variable        :which-key "describe variable")
  "h k" '(describe-key             :which-key "describe key")
  "h m" '(describe-mode            :which-key "describe mode"))
