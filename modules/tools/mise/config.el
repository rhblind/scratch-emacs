;;; modules/tools/mise/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/eki3z/mise.el][mise.el]]: per-buffer integration with the `mise' CLI (the Rust
;; rewrite of `asdf'). Reads `mise.toml' / `.tool-versions' and
;; applies the project's pinned tool versions to the buffer's local
;; `process-environment' / `exec-path', so subprocesses (LSP, compile,
;; vterm) get the right `node' / `python' / `dexter' / etc. for each
;; project.
;;
;; Pairs with `:tools direnv': both run as buffer-local env layers and
;; don't overlap (mise reads its own config; direnv reads `.envrc').

(use-package mise
  :defer t
  :hook (after-init . global-mise-mode))
