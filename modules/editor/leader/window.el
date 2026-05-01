;;; modules/editor/leader/window.el -*- lexical-binding: t; -*-
;;
;; SPC w -- window-related leader bindings. Loaded by leader/config.el.

(map! :leader
  "w"   '(:ignore t                :which-key "window")
  "w h" '(windmove-left            :which-key "left")
  "w j" '(windmove-down            :which-key "down")
  "w k" '(windmove-up              :which-key "up")
  "w l" '(windmove-right           :which-key "right")
  "w s" '(split-window-below       :which-key "split below")
  "w v" '(split-window-right       :which-key "split right")
  "w d" '(delete-window            :which-key "delete window")
  "w D" '(delete-other-windows     :which-key "delete others")
  "w m" '(scratch/toggle-maximize-window :which-key "maximize (toggle)"))
