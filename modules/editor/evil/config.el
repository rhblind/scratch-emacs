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
        evil-split-window-below t                              ; focus new window after split
        evil-vsplit-window-right t                             ; focus new window after vsplit
        evil-kill-on-visual-paste nil                          ; don't pollute the kill ring
        evil-respect-visual-line-mode t                        ; j/k follow visual lines when wrapped
        evil-shift-width tab-width)
  :config
  (evil-mode 1))

;; Override leader split bindings so the new window gets focus.
;; Deferred to `after-init-hook' so it applies regardless of module
;; load order (leader may load before or after evil).
(add-hook 'after-init-hook
  (defun scratch-evil--override-split-bindings ()
    (map! :leader
      (:prefix "w"
       :desc "split below" "s" #'evil-window-split
       :desc "split right" "v" #'evil-window-vsplit))))

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

;;;; Smart kill-word -- stop at whitespace / line boundaries instead of
;;;; eating across them (IntelliJ-style). Bound globally to
;;;; C-/M-<backspace> and C-/M-<delete> so it kicks in regardless of
;;;; evil state.

(defun scratch/backward-kill-word ()
  "Kill the previous word, stopping at whitespace / blank-line boundaries.
Falls back to a one-character delete on wide / multibyte characters
where word boundaries aren't meaningful."
  (interactive)
  (let* ((cp (point))
         (back-char (if (bobp) "" (buffer-substring cp (1- cp))))
         backword end space-pos)
    (if (= (length back-char) (string-width back-char))
        (progn
          (save-excursion
            (setq backword (buffer-substring (point)
                                             (progn (forward-word -1)
                                                    (point)))))
          (save-excursion
            (when (and backword (string-search " " backword))
              (setq space-pos (ignore-errors (search-backward " ")))))
          (save-excursion
            (let* ((pos    (ignore-errors (search-backward-regexp "\n")))
                   (substr (when pos (buffer-substring pos cp))))
              (when (or (and substr (string-empty-p (string-trim substr)))
                        (and backword (string-search "\n" backword)))
                (setq end pos))))
          (cond (end       (kill-region cp end))
                (space-pos (kill-region cp space-pos))
                (t         (backward-kill-word 1))))
      (kill-region cp (1- cp)))))

(defun scratch/forward-kill-word ()
  "Kill the next word, stopping at whitespace / blank-line boundaries.
Symmetric counterpart of `scratch/backward-kill-word'."
  (interactive)
  (let* ((cp (point))
         (forward-char (if (eobp) "" (buffer-substring cp (1+ cp))))
         forward-word end space-pos)
    (if (= (length forward-char) (string-width forward-char))
        (progn
          (save-excursion
            (setq forward-word (buffer-substring (point)
                                                 (progn (forward-word 1)
                                                        (point)))))
          (save-excursion
            (when (and forward-word (string-search " " forward-word))
              (setq space-pos (ignore-errors (search-forward " " nil t)))))
          (save-excursion
            (let* ((pos    (ignore-errors (search-forward-regexp "\n" nil t)))
                   (substr (when pos (buffer-substring cp pos))))
              (when (or (and substr (string-empty-p (string-trim substr)))
                        (and forward-word (string-search "\n" forward-word)))
                (setq end pos))))
          (cond (end       (kill-region cp end))
                (space-pos (kill-region cp space-pos))
                (t         (kill-word 1))))
      (kill-region cp (1+ cp)))))

(global-set-key (kbd "C-<backspace>") #'scratch/backward-kill-word)
(global-set-key (kbd "M-<backspace>") #'scratch/backward-kill-word)
(global-set-key (kbd "C-<delete>")    #'scratch/forward-kill-word)
(global-set-key (kbd "M-<delete>")    #'scratch/forward-kill-word)

;;;; Recenter point after scroll / search motions (implicit `zz').

(defun scratch-evil--recenter-line-a (&rest _)
  "After-advice that recenters point on its line."
  (when (bound-and-true-p evil-mode)
    (evil-scroll-line-to-center (line-number-at-pos))))

(with-eval-after-load 'evil
  (advice-add 'evil-ex-search-next     :after #'scratch-evil--recenter-line-a)
  (advice-add 'evil-ex-search-previous :after #'scratch-evil--recenter-line-a)
  (advice-add 'evil-scroll-up          :after #'scratch-evil--recenter-line-a)
  (advice-add 'evil-scroll-down        :after #'scratch-evil--recenter-line-a))

;;;; Per-state cursor color (TTY)
;;
;; In a GUI frame, evil swaps `cursor-type' on state changes and the
;; cursor color follows the `cursor' face -- the box stays visible and
;; you can tell which state you're in at a glance. In a TTY frame,
;; Emacs has no say over the cursor; the terminal owns it. Most modern
;; emulators (iTerm2, kitty, alacritty, foot, GNOME Terminal) accept
;; OSC 12 escape sequences to recolor the cursor; DECSCUSR controls the
;; shape. `evil-terminal-cursor-changer' wraps both, reading
;; `evil-<state>-state-cursor' the same way GUI evil does.
;;
;; Static literal baseline. These are always-valid colors so evil and
;; `evil-terminal-cursor-changer' have something legitimate to read
;; even if the theme refresh below hasn't run yet (or fails).
(setq evil-normal-state-cursor   '("white"  box)
      evil-motion-state-cursor   '("white"  box)
      evil-insert-state-cursor   '("white"  bar)
      evil-operator-state-cursor '("white"  box)
      evil-visual-state-cursor   '("orange" hollow)
      evil-replace-state-cursor  '("red"    box)
      evil-emacs-state-cursor    '("red"    box))

;; Theme-tracked refresh. Three layers of defence against the previous
;; "Unknown color" timer failure:
;;   1. `face-attribute ... 'default' inherits all the way to the
;;      `default' face -- never returns `unspecified' if `default'
;;      has a foreground (it always does on a live frame).
;;   2. `color-defined-p' explicitly validates the result before we
;;      assign it; on failure the static literal stays.
;;   3. `condition-case' swallows any unexpected error; the worst
;;      case is the cursor stays at the previous values, never
;;      blocks startup or breaks `enable-theme-functions'.
;; The refresh fires on `after-init-hook' (themes are settled by then)
;; and on every subsequent theme activation, so `auto-dark' /
;; `load-theme' keep colors in sync.
(defun scratch-evil--resolved-color (face attr fallback)
  "Return FACE's ATTR if it's a valid color, else FALLBACK."
  (let ((color (face-attribute face attr nil 'default)))
    (if (and (stringp color) (color-defined-p color))
        color
      fallback)))

(defun scratch-evil--refresh-state-cursors (&rest _)
  "Recompute `evil-*-state-cursor' from current theme faces and re-apply.
Updating the variables is not enough -- evil only reads them on the
next state transition. `evil-refresh-cursor' re-applies the current
state's cursor immediately so the change is visible right away."
  (condition-case err
      (progn
        ;; evil's set-cursor-color overrides the cursor face at frame
        ;; level, shadowing the theme spec.  Recalculate from theme
        ;; before reading so we get the real theme color, not the
        ;; stale frame-level value.
        (custom-theme-recalc-face 'cursor)
        (let ((theme-cursor (or (face-background 'cursor) "white")))
          (setq evil-normal-state-cursor   (list theme-cursor 'box)
                evil-motion-state-cursor   (list theme-cursor 'box)
                evil-insert-state-cursor   (list theme-cursor 'bar)
                evil-operator-state-cursor (list theme-cursor 'box)
                evil-visual-state-cursor   (list (scratch-evil--resolved-color 'warning :foreground "orange") 'hollow)
                evil-replace-state-cursor  (list (scratch-evil--resolved-color 'error   :foreground "red")    'box)
                evil-emacs-state-cursor    (list (scratch-evil--resolved-color 'error   :foreground "red")    'box)))
        (when (fboundp 'evil-refresh-cursor)
          (evil-refresh-cursor)))
    (error
     (message "scratch: cursor refresh failed (%s); keeping previous values"
              (error-message-string err)))))

;; Refresh on every signal that "we now have a real display + theme":
;;   - `after-init-hook'              : non-daemon launches.
;;   - `server-after-make-frame-hook' : first GUI frame in a daemon
;;     (in a daemon, `after-init-hook' fires before any frame
;;     exists, so faces resolve incorrectly there).
;;   - `enable-theme-functions'       : every subsequent theme switch
;;     (handles `auto-dark', manual `load-theme', etc.).
(add-hook 'after-init-hook              #'scratch-evil--refresh-state-cursors)
(add-hook 'server-after-make-frame-hook #'scratch-evil--refresh-state-cursors)
(add-hook 'enable-theme-functions       #'scratch-evil--refresh-state-cursors)

(use-package evil-terminal-cursor-changer
  :after evil
  :config
  (unless (display-graphic-p)
    (evil-terminal-cursor-changer-activate))
  ;; For daemon-spawned `emacsclient -t' clients: activate when each
  ;; new TTY frame comes up. (`activate' is idempotent enough that
  ;; double-activating from `display-graphic-p nil' above + this hook
  ;; is harmless.)
  (add-hook 'tty-setup-hook #'evil-terminal-cursor-changer-activate))
