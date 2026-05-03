;;; lisp/scratch-treesit.el --- shared treesit-auto declarations -*- lexical-binding: t; -*-
;;
;; Lang modules push the tree-sitter grammar(s) they need onto
;; `scratch-treesit-want'. The `:editor tree-sitter' module unions
;; that set with the locally-available grammars to populate
;; `treesit-auto-langs', so missing-grammar prompts and
;; `M-x treesit-auto-install-all' both cover the languages the user
;; has actually enabled (rather than just whatever happened to be
;; built on this machine).
;;
;; Defined at framework level (always loaded) so a `:lang' module
;; can safely push to it whether or not `:editor tree-sitter' is
;; enabled. With no consumer, the variable is simply unused.

(defvar scratch-treesit-want nil
  "Tree-sitter grammar symbols wanted by enabled `:lang' modules.
Each `:lang' module that benefits from a tree-sitter grammar
should `add-to-list' its grammar symbol here in its `config.el'
(e.g. `c-sharp', `go', `rust'). `:editor tree-sitter' resolves
this list against locally-installed grammars to set
`treesit-auto-langs' -- the upstream variable that gates
install prompts and `treesit-auto-install-all'.")

(provide 'scratch-treesit)
;;; scratch-treesit.el ends here
