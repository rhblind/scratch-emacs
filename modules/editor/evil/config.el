;;; modules/editor/evil/config.el -*- lexical-binding: t; -*-

;; Evil emulates vim's modal editing. Loaded eagerly because it changes
;; editing semantics globally; deferring it would leave the first frames
;; in plain Emacs mode.
;;
;; Flags:
;;   +everywhere  -- also load evil-collection (vim bindings for many
;;                   built-in and popular packages: dired, magit, etc.)

(use-package evil
  :demand t
  :init
  ;; These must be set BEFORE evil loads.
  (setq evil-want-integration t                                ; required by evil-collection
        evil-want-keybinding (not (modulep! +everywhere))      ; let evil-collection drive bindings
        evil-want-C-u-scroll t                                 ; vim-style scroll up
        evil-want-C-i-jump nil                                 ; let TAB stay TAB in terminals
        evil-want-Y-yank-to-eol t                              ; Y == y$, like vim
        evil-want-fine-undo t                                  ; one undo step per insert-mode command
        evil-undo-system 'undo-redo                            ; Emacs 28+ built-in
        evil-search-module 'evil-search                        ; richer ex-style search
        evil-ex-substitute-global t                            ; :s defaults to global on the line
        evil-kill-on-visual-paste nil                          ; don't pollute the kill ring
        evil-respect-visual-line-mode t                        ; j/k follow visual lines when wrapped
        evil-shift-width tab-width)
  :config
  (evil-mode 1))

(when (modulep! +everywhere)
  (use-package evil-collection
    :demand t
    :after evil
    :config
    (evil-collection-init)))
