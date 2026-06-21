;;; modules/llm/claude-ide/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Claude Code CLI integration via terminal + optional MCP bridge.
;; https://github.com/manzaltu/claude-code-ide.el
(straight-use-package
 '(claude-code-ide :type git :host github :repo "manzaltu/claude-code-ide.el"))

(when (modulep! +vterm)
  (straight-use-package 'vterm))
(when (modulep! +eat)
  (straight-use-package 'eat))
