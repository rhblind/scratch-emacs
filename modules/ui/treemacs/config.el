;;; modules/ui/treemacs/config.el -*- lexical-binding: t; -*-
;;
;; Adapted from Doom's :ui treemacs, minus Doom-specific helpers
;; (`set-popup-rule!', `define-key!', `after!') and modules we don't have
;; (projectile, persp, lsp-treemacs).

;; Python: treemacs core is pure elisp and runs without python. Two
;; opt-in features (extended/deferred git mode, directory collapsing
;; via `treemacs-collapse-dirs') bundle a python helper and need
;; `python3' on PATH. Our default below is `simple' git mode + no
;; collapsing, so python is NOT required out of the box. If you opt
;; into extended/deferred and python3 isn't found, the `:config'
;; block falls back to `simple' silently.

(defvar scratch-treemacs-git-mode 'simple
  "Type of git integration for `treemacs-git-mode'. One of:

  - `simple'   highlights only files based on git status; fastest.
                                                Pure elisp, no deps.
  - `extended' highlights both files and directories. Needs `python3'.
  - `deferred' same as extended but async.       Needs `python3'.

Set this BEFORE `treemacs' loads.")

(use-package treemacs
  ;; Eager so the `:config' block runs at startup -- otherwise
  ;; `treemacs-project-follow-mode' below isn't enabled until the
  ;; user invokes a treemacs command, and any buffers visited
  ;; before that don't get tracked.
  :demand t
  :init
  (setq treemacs-is-never-other-window t
        treemacs-sorting 'alphabetic-case-insensitive-asc
        treemacs-persist-file
        (expand-file-name "treemacs-persist" user-emacs-directory)
        treemacs-last-error-persist-file
        (expand-file-name "treemacs-last-error-persist" user-emacs-directory))
  :config
  ;; Two follow modes that do different things and BOTH belong on:
  ;;
  ;;   - `treemacs-project-follow-mode': swap the displayed PROJECT
  ;;     when the current buffer's project changes (cross-project
  ;;     navigation, e.g. main repo <-> a worktree).
  ;;
  ;;   - `treemacs-follow-mode': highlight / scroll-to the current
  ;;     FILE within the displayed project (cursor follow).
  ;;
  ;; Both follow modes on. There's a known race where the cursor-follow
  ;; timer fires during project-follow's tree-rebuild window and reads
  ;; an internal slot that's briefly nil, producing
  ;; `(wrong-type-argument arrayp nil)'. The advice below swallows that
  ;; transient error -- the next timer tick lands cleanly once the
  ;; rebuild settles. We made it more likely to hit this race than a
  ;; vanilla treemacs setup by tightening `treemacs--project-follow-delay'
  ;; below + adding `treemacs-persp', so the guard belongs to us.
  (treemacs-project-follow-mode 1)
  (treemacs-follow-mode 1)

  (defun scratch-treemacs--follow-guard-a (orig &rest args)
    "Swallow transient `arrayp nil' from `treemacs--follow' during rebuilds."
    (condition-case _
        (apply orig args)
      (wrong-type-argument nil)))
  (advice-add 'treemacs--follow :around #'scratch-treemacs--follow-guard-a)

  ;; Lower the project-follow debounce: upstream defaults to 1.5s of
  ;; idle, which feels like "nothing happened" -- a quick consult-
  ;; buffer / type-something flow can keep resetting the idle timer
  ;; before it fires. 0.3s lands the swap reliably without thrashing.
  (setq treemacs--project-follow-delay 0.3)

  (when scratch-treemacs-git-mode
    ;; Fall back to `simple' if `extended' / `deferred' can't find python.
    (when (and (memq scratch-treemacs-git-mode '(deferred extended))
               (not (bound-and-true-p treemacs-python-executable))
               (not (executable-find "python3")))
      (setq scratch-treemacs-git-mode 'simple))
    (treemacs-git-mode scratch-treemacs-git-mode)
    (setq treemacs-collapse-dirs
          (if (memq scratch-treemacs-git-mode '(extended deferred))
              3
            0))))

(use-package treemacs-nerd-icons
  :defer t
  :init
  ;; If lsp-treemacs is in play, defer the icon theme until it loads so it
  ;; wins the theme race; otherwise hook off plain treemacs.
  (with-eval-after-load (if (modulep! :tools lsp) 'lsp-treemacs 'treemacs)
    (require 'treemacs-nerd-icons))
  :config
  (treemacs-load-theme "nerd-icons"))

(when (modulep! :editor evil +everywhere)
  (use-package treemacs-evil
    :defer t
    :init
    (with-eval-after-load 'treemacs
      (require 'treemacs-evil))
    :config
    ;; treemacs-evil omits :tag, which makes doom-modeline crash with
    ;; (void-function nil) when it tries to display the modal indicator.
    (setq evil-treemacs-state-tag " <T> ")

    ;; Match Doom's tweak: split bindings consistent with C-w {v,s}.
    (define-key evil-treemacs-state-map (kbd "RET") #'treemacs-RET-action)
    (define-key evil-treemacs-state-map (kbd "TAB") #'treemacs-TAB-action)
    (define-key evil-treemacs-state-map (kbd "o v") #'treemacs-visit-node-horizontal-split)
    (define-key evil-treemacs-state-map (kbd "o s") #'treemacs-visit-node-vertical-split)))

(when (modulep! :emacs vc)
  (use-package treemacs-magit
    :defer t
    :init
    (with-eval-after-load 'treemacs
      (with-eval-after-load 'magit
        (require 'treemacs-magit)))))

;; `treemacs-persp' (per-persp scope shelves) is intentionally NOT
;; enabled, even when `:ui workspaces' is on. Its buffer-swap on
;; persp-activated races with persp-mode's `window-state-put' --
;; sometimes the saved window config wins, leaving the tree showing
;; the wrong project after a workspace switch. We rely instead on the
;; default frame scope (one treemacs buffer per frame) plus
;; `treemacs-project-follow-mode' to keep the tree's content in sync
;; with the active project; the workspaces module pulls treemacs
;; explicitly on persp-activated for an immediate swap.

(when (modulep! :tools lsp)
  (use-package lsp-treemacs
    :defer t
    :init
    (with-eval-after-load 'treemacs
      (require 'lsp-treemacs))))

;;;; Bindings

;; M-0 globally focuses (or pops up) the treemacs window -- the same
;; "window 0" mental model used for the numbered windows in
;; `lisp/scratch-window.el'. State-aware so it wins over evil-collection
;; aux maps in magit, dired, etc. (same trick used by the M-1..M-9
;; window-select bindings).
(general-define-key
 :states '(normal visual motion emacs insert hybrid replace operator)
 :keymaps 'override
 (kbd "M-0") #'treemacs-select-window)

(when (modulep! :editor leader)
  (map! :leader
        (:prefix-map ("o" . "open")
                     :desc "project tree (treemacs)"  "p" #'treemacs
                     :desc "find file in tree"        "P" #'treemacs-find-file)))
