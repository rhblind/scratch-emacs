;;; modules/editor/leader/buffer.el -*- lexical-binding: t; -*-
;;
;; SPC b -- buffer-related leader bindings. Loaded by leader/config.el.
;; Helper commands (`scratch/scratch-buffer', etc.) live framework-wide
;; in `lisp/scratch-buffer.el'; window numbering helpers
;; (`scratch/buffer-to-window-N') in `lisp/scratch-window.el'.

(map! :leader
      (:prefix-map ("b" . "buffer")
                   :desc "switch buffer"     "b" #'switch-to-buffer
                   :desc "next buffer"       "n" #'next-buffer
                   :desc "prev buffer"       "p" #'previous-buffer
                   :desc "clone buffer"      "c" #'clone-indirect-buffer
                   :desc "clone (other win)" "C" #'clone-indirect-buffer-other-window
                   :desc "kill buffer"       "d" #'kill-current-buffer
                   :desc "kill buffer"       "k" #'kill-current-buffer
                   :desc "kill all buffers"  "K" #'scratch/kill-all-buffers
                   :desc "kill other buffers" "O" #'scratch/kill-other-buffers
                   :desc "ibuffer"           "i" #'ibuffer
                   :desc "revert buffer"     "r" #'revert-buffer
                   :desc "rename buffer"     "R" #'rename-buffer
                   :desc "save buffer"       "s" #'save-buffer
                   :desc "save all buffers"  "S" #'save-some-buffers
                   :desc "last buffer"       "l" #'scratch/switch-to-last-buffer
                   :desc "*scratch*"         "x" #'scratch/scratch-buffer
                   :desc "new empty buffer"  "N" #'scratch/new-empty-buffer
                   :desc "erase buffer"      "e" #'scratch/erase-buffer
                   :desc "yank buffer"       "y" #'scratch/yank-buffer
                   :desc "copy filepath"      "Y" #'scratch/copy-buffer-filepath
                   :desc "paste over buffer" "P" #'scratch/replace-buffer-from-clipboard
                   ;; Move (or, with prefix arg, swap) current buffer to window N. M-N
                   ;; globally focuses the corresponding window.
                   :desc "to window 1"       "1" #'scratch/buffer-to-window-1
                   :desc "to window 2"       "2" #'scratch/buffer-to-window-2
                   :desc "to window 3"       "3" #'scratch/buffer-to-window-3
                   :desc "to window 4"       "4" #'scratch/buffer-to-window-4
                   :desc "to window 5"       "5" #'scratch/buffer-to-window-5
                   :desc "to window 6"       "6" #'scratch/buffer-to-window-6
                   :desc "to window 7"       "7" #'scratch/buffer-to-window-7
                   :desc "to window 8"       "8" #'scratch/buffer-to-window-8
                   :desc "to window 9"       "9" #'scratch/buffer-to-window-9))
