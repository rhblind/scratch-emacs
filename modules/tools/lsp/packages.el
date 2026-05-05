;;; modules/tools/lsp/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; lsp-mode wants `LSP_USE_PLISTS=1' set BEFORE the package compiles
;; (it switches its internal data shape). Set the env var early; the
;; user's shell will see this in any subprocess that lsp-mode spawns.
(setenv "LSP_USE_PLISTS" "1")

(straight-use-package 'spinner)
(straight-use-package 'lsp-mode)
(straight-use-package 'lsp-ui)

;; consult-lsp: lsp results in a consult picker (workspace symbols,
;; file symbols, diagnostics).
(when (modulep! :completion vertico)
  (straight-use-package 'consult-lsp))
