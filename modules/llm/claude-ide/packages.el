;;; modules/llm/claude-ide/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Claude Code CLI integration via terminal + optional MCP bridge.
;; https://github.com/manzaltu/claude-code-ide.el
(straight-use-package
 '(claude-code-ide :type git :host github :repo "manzaltu/claude-code-ide.el"))

;; The default terminal backend (vterm) is installed by `:term vterm'.
;; Only `eat' needs an explicit install here.
(when (modulep! +eat)
  (straight-use-package 'eat))
