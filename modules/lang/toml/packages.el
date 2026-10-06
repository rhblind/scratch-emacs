;;; modules/lang/toml/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Nothing to install. `toml-ts-mode' is built into Emacs 30
;; (textmodes/toml-ts-mode.el) and routes `.toml' to itself once the
;; tree-sitter grammar is available (managed by treesit-auto via
;; `:editor tree-sitter', or installable standalone -- source
;; registered in config.el). Without the grammar, vanilla's
;; `conf-toml-mode' handles the file cleanly.
;;
;; LSP comes from lsp-mode's built-in `lsp-toml' client
;; (`:tools lsp'): taplo, expected on $PATH
;; (`brew install taplo' / `cargo install taplo-cli --locked'
;; / `npm install -g @taplo/lib taplo-cli'). taplo ships editor
;; schemas, so pyproject.toml ([project], [tool.uv], [tool.ruff],
;; [tool.pytest.ini_options]), Cargo.toml, and mise.toml all get
;; completion + validation. lsp-mode's `lsp-toml-tombi' client exists
;; as an alternative; it registers at lower priority, so with both
;; binaries installed taplo wins.
