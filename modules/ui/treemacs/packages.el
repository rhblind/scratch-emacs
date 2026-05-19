;;; modules/ui/treemacs/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'treemacs)
(straight-use-package 'treemacs-nerd-icons)

(when (modulep! :editor evil +everywhere)
  (straight-use-package 'treemacs-evil))

(when (modulep! :emacs vc)
  (straight-use-package 'treemacs-magit))

;; Pre-wired integrations -- no-ops until these modules are added.
;; `treemacs-persp' is intentionally NOT installed -- its buffer-swap
;; on persp activation races with persp-mode's window-state restore.
;; The workspaces module bridges to treemacs via a hook in its config
;; instead. See `:ui treemacs/config.el' and `:ui workspaces/config.el'.

(when (modulep! :tools lsp)
  (straight-use-package 'lsp-treemacs))
