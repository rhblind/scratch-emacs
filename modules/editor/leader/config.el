;;; modules/editor/leader/config.el -*- lexical-binding: t; -*-
;;
;; Leader key infrastructure: SPC-prefixed transient menus (Doom / Spacemacs
;; style) backed by general.el and which-key.
;;
;; The `map!' macro and the leader / localleader prefix defvars
;; (`scratch-leader-key', etc.) live framework-wide in
;; `lisp/scratch-keys.el'. This module:
;;
;; - configures which-key (the discovery popup),
;; - enables `general-override-mode' and turns its map into an evil
;;   intercept map (so `SPC' wins in *Messages*, magit, dired, etc.),
;; - defines the `scratch-leader-def' general definer (function form,
;;   if you prefer it over `map!'),
;; - loads sibling files for each leader submenu:
;;     file.el     -- SPC f
;;     buffer.el   -- SPC b
;;     window.el   -- SPC w
;;     help.el     -- SPC h
;;     quit.el     -- SPC q
;;     project.el  -- SPC p (+ scratch/list-projects helper)
;;
;; Submenus owned by other modules live in those modules:
;;   :emacs vc          -- SPC g (magit, browse-at-remote, git-timemachine)
;;   :completion vertico -- SPC s, SPC y, and consult overrides for b/f/p

(defvar scratch-leader--dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing this leader-module file. Used to load sibling files.")

;; which-key: pop up available bindings after a short pause.
(use-package which-key
  :demand t
  :init
  (setq which-key-idle-delay 0.3
        which-key-popup-type 'side-window
        which-key-side-window-location 'bottom
        which-key-side-window-max-height 0.4)
  :config
  (which-key-mode 1))

;; general.el setup. (Installed framework-wide; here we configure it.)
(use-package general
  :demand t
  :config
  ;; `override' forces these bindings to win over major-mode and
  ;; minor-mode keymaps, which is what you want for a leader.
  (general-override-mode 1)
  ;; Make `general-override-mode-map' an evil *intercept* map for the
  ;; relevant states so SPC wins over `evil-motion-state-map' bindings
  ;; like `evil-forward-char' (active in *Messages*, magit, etc.).
  (general-override-make-intercept-maps
   nil '(insert emacs hybrid normal visual motion operator replace))

  ;; Function-form definer (alternative to `map!').
  (general-create-definer scratch-leader-def
    :states '(normal visual motion emacs insert)
    :keymaps 'override
    :prefix scratch-leader-key
    :non-normal-prefix scratch-leader-non-normal-key)

  ;; Top-level shortcuts.
  (map! :leader
    :desc "M-x"            "SPC" #'execute-extended-command
    :desc "M-x"            ":"   #'execute-extended-command
    :desc "find file"      "."   #'find-file
    :desc "switch buffer"  ","   #'switch-to-buffer
    :desc "list processes" "P"   #'list-processes
    :desc "last buffer"    "TAB" #'scratch/switch-to-last-buffer)

  ;; Per-topic submenus -- auto-discovered. Drop a new `<topic>.el' in
  ;; this directory and it gets loaded automatically. `config.el' (this
  ;; file) and `packages.el' are excluded so they don't load themselves.
  (let ((self (file-name-nondirectory (or load-file-name buffer-file-name))))
    (dolist (file (directory-files scratch-leader--dir t "\\.el\\'"))
      (unless (member (file-name-nondirectory file)
                      (list self "packages.el"))
        (load file nil 'nomessage)))))
