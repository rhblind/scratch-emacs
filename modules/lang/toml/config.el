;;; modules/lang/toml/config.el -*- lexical-binding: t; -*-
;;
;; TOML support. Built-in `toml-ts-mode' (Emacs 30, tree-sitter based)
;; for `.toml'; tree-sitter only, no legacy fallback. Vanilla maps
;; `.toml' to `conf-toml-mode' until the grammar is installed, which is
;; a serviceable viewer -- treesit-auto's install prompt covers the
;; upgrade path.
;;
;; TOML is the config lingua franca of several other modules'
;; ecosystems, so this module is deliberately small and generic:
;;
;;   - pyproject.toml / uv.lock / ruff.toml / ty.toml  (`:lang python')
;;   - Cargo.toml / Cargo.lock                          (`:lang rust')
;;   - mise.toml                                        (`:tools mise')
;;
;; LSP (with `:tools lsp') via lsp-mode's built-in `lsp-toml' client:
;; taplo (`taplo lsp stdio', multi-root, no add-on -- it is the primary
;; server for toml buffers). taplo bundles schemas for pyproject.toml,
;; Cargo.toml, mise.toml and friends, so table keys get completion and
;; validation out of the box. Install: `brew install taplo'.
;;
;; No localleader: there are no toml-specific commands worth binding.

;; Tell `:editor tree-sitter' that we want the toml grammar managed by
;; treesit-auto. Idempotent; no-op when tree-sitter isn't enabled.
(add-to-list 'scratch-treesit-want 'toml)

;; Grammar source as a fallback for users without `:editor tree-sitter'
;; (treesit-auto otherwise provides this via its recipe list). Lets
;; `M-x treesit-install-language-grammar RET toml' work standalone.
;; The maintained grammar lives in the tree-sitter-grammars org (the
;; original tree-sitter/tree-sitter-toml repo is stale). No rev pin:
;; the current grammar works with the ABI Emacs 30 ships.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(toml "https://github.com/tree-sitter-grammars/tree-sitter-toml")))

;; `toml-ts-mode.el' self-registers `.toml' -> `toml-ts-mode' at load
;; time when the grammar is ready (mirrors python.el), so no
;; auto-mode-alist / remap entries needed here.

;; LSP: `toml-ts-mode' into `:tools lsp' auto-attach. lsp-mode already
;; maps `toml-ts-mode' -> "toml" in `lsp-language-id-configuration',
;; and the taplo client's activation predicate matches on that
;; language id, so nothing else to register.
(when (modulep! :tools lsp)
  (add-to-list 'scratch-lsp-auto-modes 'toml-ts-mode))
