;;; scratch-lsp.el --- shared LSP defvars across modules -*- lexical-binding: t; -*-
;;
;; Lives in `lisp/' (eagerly required by init.el) so language modules
;; can contribute to `scratch-lsp-auto-modes' before
;; `:tools lsp/config.el' reads it. The previous design defined the
;; var inside the lsp module with a hardcoded seed list of every
;; language we might support, which forced the lsp module to know
;; about every language up front -- the wrong direction of dependency.

(defvar scratch-lsp-auto-modes nil
  "Major modes that should auto-attach `lsp-deferred' on entry.

Language modules add their modes to this list (gated on
`(modulep! :tools lsp)') so enabling a new language doesn't require
touching `:tools lsp/config.el'. The lsp module reads the list when
wiring its mode hooks.

Override or extend from user config BEFORE `(scratch! ...)' runs to
add modes the framework doesn't ship a module for, e.g.:

  (with-eval-after-load 'scratch-lsp
    (add-to-list 'scratch-lsp-auto-modes 'rust-ts-mode))")

(provide 'scratch-lsp)
;;; scratch-lsp.el ends here
