;;; modules/editor/leader/window.el -*- lexical-binding: t; -*-
;;
;; SPC w -- window management. Maps to evil-window-map (vim's C-w
;; prefix) so all standard vim window commands work, plus extras.
;; Loaded by leader/config.el.

(winner-mode 1)

(map! :leader
  :desc "window" "w" evil-window-map)

(map! :map evil-window-map
  "d"   #'evil-window-delete
  "D"   #'delete-other-windows
  "m"   #'scratch/toggle-maximize-window
  "u"   #'winner-undo
  "C-u" #'winner-undo
  "C-r" #'winner-redo
  "T"   #'tear-off-window)
