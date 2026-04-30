;;; modules/emacs/vc/config.el -*- lexical-binding: t; -*-
;;
;; Version control: built-in `vc' tweaks plus magit (and optionally forge).
;;
;; Flags:
;;   +forge  -- enable forge (GitHub / GitLab issues + PRs inside magit).
;;              Requires an authinfo entry for your forge token; see
;;              C-h f forge-add-repository.

;; Built-in version control.
(setq vc-follow-symlinks nil)  ; edit symlinks directly, don't auto-follow

;; Magit -- the git porcelain.
(use-package magit
  :defer t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :config
  (setq magit-diff-refine-hunk t                  ; fine-grained diffs within hunks
        magit-save-repository-buffers 'dontask))  ; auto-save buffers, no prompt

;; Forge -- GitHub / GitLab integration on top of magit.
(when (modulep! +forge)
  (use-package forge
    :after magit))
