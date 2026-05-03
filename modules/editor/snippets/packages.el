;;; modules/editor/snippets/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'yasnippet)
(straight-use-package 'yasnippet-snippets)

;; consult-yasnippet -- consult-driven picker for inserting snippets,
;; gated on vertico (matches the rest of the framework's consult bits).
(when (modulep! :completion vertico)
  (straight-use-package 'consult-yasnippet))
