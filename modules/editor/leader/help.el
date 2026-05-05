;;; modules/editor/leader/help.el -*- lexical-binding: t; -*-
;;
;; SPC h -- help. Bound directly to Emacs' built-in `help-map' so we
;; inherit every standard `C-h <key>' command (`describe-function' /
;; `-variable' / `-key' / `-mode', `apropos', `where-is',
;; `view-lossage', ...) without re-declaring them. Customisations
;; below mutate `help-map' itself, so they apply to both `SPC h' and
;; `C-h'.

;; `:desc' wraps the def in `(SYM :which-key ...)' and general.el then
;; treats SYM as a command. `help-map' is a keymap, not a command, so
;; bind it bare and label the prefix via which-key separately.
(map! :leader "h" help-map)
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    (concat scratch-leader-key " h") "help"))

;;;; Bindings submenu (`SPC h b ...').
;;
;; Stock Emacs binds `b' to `describe-bindings'; turn it into a prefix
;; and put the which-key inspectors underneath. `bb' keeps the original
;; `describe-bindings', mirroring Doom's layout.

(define-key help-map "b" nil)
(define-key help-map (kbd "b b") #'describe-bindings)
(define-key help-map (kbd "b m") #'which-key-show-major-mode)
(define-key help-map (kbd "b i") #'which-key-show-minor-mode-keymap)
(define-key help-map (kbd "b t") #'which-key-show-top-level)
(define-key help-map (kbd "b f") #'which-key-show-full-keymap)
(define-key help-map (kbd "b k") #'which-key-show-keymap)
(with-eval-after-load 'which-key
  (which-key-add-keymap-based-replacements help-map "b" "bindings"))

;;;; Replacements on top-level `help-map'.
;;
;; `t' was `help-with-tutorial' (rarely used after onboarding); reuse
;; for `load-theme'. `F' was `Info-goto-emacs-command-node' (redundant
;; with `Info-goto-node'); reuse for `describe-face'.

(define-key help-map "t" #'load-theme)
(define-key help-map "F" #'describe-face)

;;;; Profiler toggle on `T'.

(defun scratch/toggle-profiler ()
  "Toggle the Emacs profiler.
First call starts cpu+mem profiling; second call stops and pops the
`*Profiler-Report*' buffer."
  (interactive)
  (if (or (profiler-cpu-running-p) (profiler-memory-running-p))
      (progn (profiler-stop) (profiler-report))
    (profiler-start 'cpu+mem)
    (message "Profiler started (cpu+mem). Run `SPC h T' again to stop and report.")))

(define-key help-map "T" #'scratch/toggle-profiler)
