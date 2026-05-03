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
        evil-want-C-d-scroll t                                 ; vim-style scroll down
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
  ;; Set evil-collection knobs BEFORE `evil-collection-init' runs so the
  ;; bindings it generates pick them up.
  (setq evil-collection-setup-minibuffer t                     ; full evil bindings in vertico, etc.
        evil-collection-vertico-want-want-C-u-in-insert t)     ; C-u scroll-up while typing in minibuffer
  (use-package evil-collection
    :demand t
    :after evil
    :config
    (evil-collection-init)))

;; evil-surround: `ys' / `cs' / `ds' to add / change / delete the
;; surround pair around a text object. Universally expected by anyone
;; coming from vim's tpope/vim-surround.
(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

;; evil-numbers: increment / decrement the integer at point. Bound
;; under `g' to avoid stomping on `C-a' / `C-x' (terminal / tmux). Same
;; bindings Doom uses by default.
(use-package evil-numbers
  :after evil
  :commands (evil-numbers/inc-at-pt
             evil-numbers/dec-at-pt
             evil-numbers/inc-at-pt-incremental
             evil-numbers/dec-at-pt-incremental)
  :init
  (with-eval-after-load 'evil
    (map! :n "g=" #'evil-numbers/inc-at-pt
          :n "g-" #'evil-numbers/dec-at-pt
          :v "g=" #'evil-numbers/inc-at-pt-incremental
          :v "g-" #'evil-numbers/dec-at-pt-incremental)))

;; evil-nerd-commenter: `gc' as a vim-style comment operator. `gcc'
;; toggles the current line, `gc{motion}' / `gc` in visual toggles a
;; region.
(use-package evil-nerd-commenter
  :after evil
  :commands (evilnc-comment-operator
             evilnc-inner-comment
             evilnc-outer-commenter)
  :init
  (with-eval-after-load 'evil
    (map! :nv "gc"  #'evilnc-comment-operator)))

;; avy: jump anywhere visible by typing a few characters and selecting
;; a candidate via single-key picks (e.g. type `gss' then 2 chars,
;; avy decorates every match with a letter -- press the letter to
;; jump). Replaces the role evil-snipe used to play, without rebinding
;; foundational motion keys (`f'/`t'/`,'/`;'/`s' all stay vim-classic).
(use-package avy
  :defer t
  :commands (avy-goto-char
             avy-goto-char-2
             avy-goto-char-timer
             avy-goto-line
             avy-goto-word-0
             avy-goto-word-1)
  :init
  (setq avy-timeout-seconds 0.3            ; how long the timer variant waits
        avy-style          'at-full        ; show overlay over the matched chars
        avy-all-windows    nil))           ; only the selected window by default

;; Bindings outside `use-package' so they install as soon as evil
;; loads, not deferred until avy itself is required. avy commands are
;; autoloaded, so the first `gs s' press loads + runs the package.
(with-eval-after-load 'evil
  (map! :nv "gs s"   #'avy-goto-char-2
        :nv "gs SPC" #'avy-goto-char-timer
        :nv "gs c"   #'avy-goto-char
        :nv "gs l"   #'avy-goto-line
        :nv "gs w"   #'avy-goto-word-1
        :nv "gs W"   #'avy-goto-word-0))

;; evil-matchit: `%' jumps between matching pairs (parens, brackets,
;; HTML tags, function start/end, language-specific delimiters).
(use-package evil-matchit
  :after evil
  :config
  (global-evil-matchit-mode 1))

;; evil-args: text object for function arguments. `cia' changes the
;; argument under point (without the surrounding comma); `caa' changes
;; with the comma. Bind under `a' in the inner / outer text-object
;; maps so `ia' / `aa' compose with any operator (`d', `c', `y', ...).
(use-package evil-args
  :after evil
  :config
  (define-key evil-inner-text-objects-map "a" #'evil-inner-arg)
  (define-key evil-outer-text-objects-map "a" #'evil-outer-arg))
