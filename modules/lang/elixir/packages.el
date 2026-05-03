;;; modules/lang/elixir/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; `elixir-ts-mode' / `heex-ts-mode' ship built-in (Emacs 30+); no
;; external mode pkg. `exunit' adds test-runner commands.
;;
;; Linting layers (when `:checkers syntax' is on); they cover
;; different ground and run together:
;;   - `lsp-credo' (bundled with lsp-mode): runs as an LSP add-on
;;     alongside the main elixir server, so credo warnings stream in
;;     live as you type. Install once with `M-x lsp-install-server
;;     credo-language-server' -- no separate elisp package.
;;   - `flycheck-credo': runs the `credo' CLI binary as a flycheck
;;     checker. Catches anything the LSP server misses (full project
;;     scan vs the LSP's per-file view) and works without the server.
;;   - `flycheck-dialyxir': runs Dialyzer via `mix dialyzer' as a
;;     flycheck checker -- the only path for type / spec warnings;
;;     chained after the `lsp' checker so dialyxir's findings layer
;;     on top of LSP diagnostics.

(straight-use-package 'exunit)

(when (modulep! :checkers syntax)
  (straight-use-package 'flycheck-credo)
  (straight-use-package 'flycheck-dialyxir))
