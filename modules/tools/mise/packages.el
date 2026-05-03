;;; modules/tools/mise/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; mise.el (eki3z): per-buffer integration with `mise', the Rust
;; rewrite of asdf. Reads `mise.toml' / `.tool-versions' and applies
;; the project's pinned tool versions to the buffer's local env.
(straight-use-package
 '(mise :type git :host github :repo "eki3z/mise.el"))
