;;; modules/emacs/vc/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'magit)
(straight-use-package 'magit-todos)

(when (modulep! +forge)
  (straight-use-package 'forge))

;; Open the remote URL (GitHub/GitLab/Codeberg) for the current line/region.
(straight-use-package 'browse-at-remote)

;; Step through a file's git history. Mirror the Doom recipe -- the
;; original lives on codeberg, which has spotty uptime; emacsmirror is more reliable.
(straight-use-package
 '(git-timemachine :type git :host github :repo "emacsmirror/git-timemachine"))

;; Major modes for .gitconfig, .gitignore, .gitattributes.
(straight-use-package 'git-modes)

;; +gutter -- live VCS hunk indicators in the fringe / margin via diff-hl.
(when (modulep! +gutter)
  (straight-use-package 'diff-hl))
