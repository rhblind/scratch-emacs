;;; modules/lang/rust/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; No external packages required. Everything ships with Emacs 30+ and
;; the enabled modules:
;;
;;   - `rust-ts-mode': built-in tree-sitter major mode for `.rs'. The
;;     grammar comes from treesit-auto (`:editor tree-sitter') or the
;;     source alist registered in config.el (`M-x
;;     treesit-install-language-grammar RET rust').
;;
;;   - LSP: lsp-mode's built-in `lsp-rust' client (rust-analyzer).
;;     The binary is expected on PATH (`rustup component add
;;     rust-analyzer'); `M-x lsp-install-server' can also fetch it.
;;
;;   - Flycheck: the built-in `rust-cargo' checker (`:checkers
;;     syntax'). config.el teaches it to detect binary-only crates
;;     (Cargo.toml without a [lib] target), where the default
;;     `--lib' invocation fails with "no library targets found".
;;
;;   - Formatting: rustfmt via apheleia's default `rustfmt' formatter
;;     and rust-analyzer's `textDocument/formatting' (`:editor
;;     format' prefers LSP when a server is attached). Nothing to do.
