;;; modules/lang/python/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; No external package is required for the major mode: `python-ts-mode'
;; is built into Emacs 29+, and the python tree-sitter grammar is
;; managed by treesit-auto (`:editor tree-sitter') or installable with
;; `M-x treesit-install-language-grammar RET python' (source registered
;; in config.el).
;;
;; LSP needs no packages either. lsp-mode (`:tools lsp') ships the
;; clients we use:
;;
;;   - `lsp-python-ty' -- `ty server' (types, navigation, completions,
;;     inlay hints, code actions). Astral's type checker; beta-quality
;;     but first-class in lsp-mode.
;;
;;   - `lsp-ruff' -- `ruff server' add-on client. Runs alongside ty and
;;     contributes lint diagnostics, organize-imports and fix-all code
;;     actions. Both servers resolve the project `.venv' on their own,
;;     so no venv plumbing is needed for LSP.
;;
;; Both binaries are expected on $PATH:
;;   uv tool install ty ruff        (or: brew install ruff && uv tool install ty)
;;
;; Actual package installs below:
;;
;;   - python-pytest: pytest runner wired to localleader `t' bindings
;;     (mirrors `:lang elixir''s exunit integration).
;;
;; Debugging goes through dape, which lives in its own `:tools dape'
;; module; this module's `+debug' flag registers the debugpy adapter
;; config and bindings (see config.el).

(straight-use-package 'python-pytest)
