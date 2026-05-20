;;; scratch-vc.el --- shared VC defvars across modules -*- lexical-binding: t; -*-
;;
;; Lives in `lisp/' (eagerly required by init.el) so that any module
;; can reference these variables regardless of load order.

(defvar scratch-vc-worktree-dir-name ".worktrees"
  "Directory name (relative to a repo root) that holds git worktrees.
Referenced by `:emacs vc' (magit worktree creation) and `:tools lsp'
(worktree-aware workspace isolation).")

(provide 'scratch-vc)
;;; scratch-vc.el ends here
