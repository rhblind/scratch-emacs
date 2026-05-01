;;; modules/editor/leader/buffer.el -*- lexical-binding: t; -*-
;;
;; SPC b -- buffer-related leader bindings. Loaded by leader/config.el.
;; Helper commands (`scratch/scratch-buffer', etc.) live framework-wide
;; in `lisp/scratch-buffer.el'.

(map! :leader
  "b"   '(:ignore t                          :which-key "buffer")
  "b b" '(switch-to-buffer                   :which-key "switch buffer")
  "b ]" '(next-buffer                        :which-key "next buffer")
  "b [" '(previous-buffer                    :which-key "previous buffer")
  "b n" '(next-buffer                        :which-key "next buffer")
  "b p" '(previous-buffer                    :which-key "previous buffer")
  "b c" '(clone-indirect-buffer              :which-key "clone buffer")
  "b C" '(clone-indirect-buffer-other-window :which-key "clone in other window")
  "b d" '(kill-current-buffer                :which-key "kill buffer")
  "b k" '(kill-current-buffer                :which-key "kill buffer")
  "b K" '(scratch/kill-all-buffers           :which-key "kill all buffers")
  "b O" '(scratch/kill-other-buffers         :which-key "kill other buffers")
  "b i" '(ibuffer                            :which-key "ibuffer")
  "b r" '(revert-buffer                      :which-key "revert buffer")
  "b R" '(rename-buffer                      :which-key "rename buffer")
  "b s" '(save-buffer                        :which-key "save buffer")
  "b S" '(save-some-buffers                  :which-key "save all buffers")
  "b l" '(scratch/switch-to-last-buffer      :which-key "last buffer")
  "b x" '(scratch/scratch-buffer             :which-key "*scratch*")
  "b N" '(scratch/new-empty-buffer           :which-key "new empty buffer")
  "b e" '(erase-buffer                       :which-key "erase buffer")
  "b Y" '(scratch/copy-buffer-filepath       :which-key "copy filepath:line")
  "b P" '(scratch/replace-buffer-from-clipboard :which-key "paste over buffer")

  ;; Move (or, with prefix arg, swap) current buffer to window N.
  ;; See `lisp/scratch-window.el'. M-N globally focuses window N.
  "b 1" '(scratch/buffer-to-window-1 :which-key "to window 1")
  "b 2" '(scratch/buffer-to-window-2 :which-key "to window 2")
  "b 3" '(scratch/buffer-to-window-3 :which-key "to window 3")
  "b 4" '(scratch/buffer-to-window-4 :which-key "to window 4")
  "b 5" '(scratch/buffer-to-window-5 :which-key "to window 5")
  "b 6" '(scratch/buffer-to-window-6 :which-key "to window 6")
  "b 7" '(scratch/buffer-to-window-7 :which-key "to window 7")
  "b 8" '(scratch/buffer-to-window-8 :which-key "to window 8")
  "b 9" '(scratch/buffer-to-window-9 :which-key "to window 9"))
