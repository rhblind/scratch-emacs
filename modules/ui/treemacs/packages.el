;;; modules/ui/treemacs/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'treemacs)
(straight-use-package 'treemacs-nerd-icons)
(straight-use-package 'treemacs-icons-dired)

(when (modulep! :editor evil +everywhere)
  (straight-use-package 'treemacs-evil))

(when (modulep! :emacs vc)
  (straight-use-package 'treemacs-magit))

;; Pre-wired integrations -- no-ops until these modules are added.
(when (modulep! :ui workspaces)
  (straight-use-package 'treemacs-persp))

(when (modulep! :tools lsp)
  (straight-use-package 'lsp-treemacs))
