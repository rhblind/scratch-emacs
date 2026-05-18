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
        evil-shift-width 2)
  :config
  (evil-mode 1)
  (add-hook 'after-change-major-mode-hook
            (defun scratch-evil--sync-shift-width ()
              (setq-local evil-shift-width tab-width)))
  (map! :n "<escape>" #'evil-ex-nohighlight))


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

;;;; Visual-mode shift -- `>' / `<' keep the selection so you can
;;;; repeat without reselecting.

(defun scratch-evil/visual-shift-right ()
  "Shift region right and reselect."
  (interactive)
  (call-interactively #'evil-shift-right)
  (evil-normal-state)
  (evil-visual-restore))

(defun scratch-evil/visual-shift-left ()
  "Shift region left and reselect."
  (interactive)
  (call-interactively #'evil-shift-left)
  (evil-normal-state)
  (evil-visual-restore))

(with-eval-after-load 'evil
  (evil-define-key 'visual 'global
    ">" #'scratch-evil/visual-shift-right
    "<" #'scratch-evil/visual-shift-left))

;;;; End-of-visual-line motion
;;
;; A proper evil motion wrapping `end-of-visual-line'.  Defining it
;; with `evil-define-motion' and `:type inclusive' lets evil's visual
;; selection machinery include the last visible character correctly.

(with-eval-after-load 'evil
  (evil-define-motion scratch-evil/end-of-visual-line (count)
    "Move to the last character of the current visual line."
    :type inclusive
    (end-of-visual-line count)
    (unless (or (evil-visual-state-p) (bolp))
      (backward-char))))

;;;; Linewise yank promotion
;;
;; Ensure that full-line yanks always have a linewise yank-handler on
;; the kill-ring entry so `p' pastes on a new line.  Covers both the
;; `V y' case (safety net when evil's own handler is missing) and
;; characterwise visual yanks that happen to span complete lines.

(defun scratch-evil--promote-linewise-yank-a (beg end &optional type register _yank-handler)
  "Ensure full-line yanks paste linewise.
After-advice for `evil-yank'.  For linewise yanks and for
characterwise yanks that span complete lines, set the yank-handler
to `evil-yank-line-handler' so `p' opens a new line."
  (when (and (not register) kill-ring)
    (let* ((text (car kill-ring))
           (eff-end (if (eq type 'inclusive) (1+ end) end)))
      (when (and text
                 (or (eq type 'line)
                     (and (memq type '(inclusive exclusive))
                          (save-excursion (goto-char beg) (bolp))
                          (save-excursion
                            (goto-char eff-end)
                            (or (eolp)
                                (and (bolp) (> eff-end beg)))))))
        (unless (string-suffix-p "\n" text)
          (setcar kill-ring (concat text "\n")))
        (put-text-property 0 (length (car kill-ring))
                           'yank-handler '(evil-yank-line-handler)
                           (car kill-ring))))))

(with-eval-after-load 'evil
  (advice-add 'evil-yank :after #'scratch-evil--promote-linewise-yank-a))

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
