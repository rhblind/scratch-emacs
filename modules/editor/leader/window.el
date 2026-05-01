;;; modules/editor/leader/window.el -*- lexical-binding: t; -*-
;;
;; SPC w -- window-related leader bindings. Loaded by leader/config.el.

(map! :leader
  (:prefix-map ("w" . "window")
   :desc "left"             "h" #'windmove-left
   :desc "down"             "j" #'windmove-down
   :desc "up"               "k" #'windmove-up
   :desc "right"            "l" #'windmove-right
   :desc "split below"      "s" #'split-window-below
   :desc "split right"      "v" #'split-window-right
   :desc "delete window"    "d" #'delete-window
   :desc "delete others"    "D" #'delete-other-windows
   :desc "maximize (toggle)" "m" #'scratch/toggle-maximize-window))
