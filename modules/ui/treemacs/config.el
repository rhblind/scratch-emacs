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
  :defer t
  :init
  (setq treemacs-follow-after-init t
        treemacs-is-never-other-window t
        treemacs-sorting 'alphabetic-case-insensitive-asc
        treemacs-persist-file
        (expand-file-name "treemacs-persist" user-emacs-directory)
        treemacs-last-error-persist-file
        (expand-file-name "treemacs-last-error-persist" user-emacs-directory))
  :config
  (treemacs-follow-mode t)

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

(when (modulep! :ui workspaces)
  (use-package treemacs-persp
    :defer t
    :init
    (with-eval-after-load 'treemacs
      (require 'treemacs-persp))
    :config
    (treemacs-set-scope-type 'Perspectives)))

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
     :desc "project tree (treemacs)" "p" #'treemacs
     :desc "find file in tree"       "P" #'treemacs-find-file)))
