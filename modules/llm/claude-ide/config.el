;;; modules/llm/claude-ide/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/manzaltu/claude-code-ide.el][claude-code-ide.el]]: native integration with the Claude Code CLI
;; through a terminal (vterm or eat) and optional MCP bridge. Provides
;; project-aware session management, ediff review, and Emacs tool
;; exposure (xref, treesit, imenu, diagnostics) to the Claude agent.
;;
;; Flags:
;;   +mcp       enable MCP server + Emacs tools
;;   +ide-diff  enable ediff review for code changes
;;   +vterm     force vterm terminal backend
;;   +eat       force eat terminal backend (needs +eat in packages.el)
;;
;; Default terminal backend is vterm (via `:term vterm').

(use-package claude-code-ide
  :commands (claude-code-ide
             claude-code-ide-send-prompt
             claude-code-ide-continue
             claude-code-ide-resume
             claude-code-ide-list-sessions
             claude-code-ide-menu)
  :init
  ;; Terminal backend: explicit flag wins, otherwise package default (vterm).
  (when (modulep! +vterm)
    (setq claude-code-ide-terminal-backend 'vterm))
  (when (modulep! +eat)
    (setq claude-code-ide-terminal-backend 'eat))

  ;; IDE diff: off by default, opt-in via +ide-diff.
  (setq claude-code-ide-use-ide-diff (and (modulep! +ide-diff) t))

  ;; MCP server: off by default, opt-in via +mcp.
  (when (modulep! +mcp)
    (setq claude-code-ide-enable-mcp-server t)))

;; MCP tools setup must run after the package loads.
(when (modulep! +mcp)
  (with-eval-after-load 'claude-code-ide
    (claude-code-ide-emacs-tools-setup)))

;; Leader bindings under SPC A c (AI > claude).
(when (modulep! :editor leader)
  (map! :leader
    (:prefix-map ("A" . "AI")
     (:prefix-map ("c" . "claude")
      :desc "start claude code"   "c" #'claude-code-ide
      :desc "send prompt"         "s" #'claude-code-ide-send-prompt
      :desc "continue"            "C" #'claude-code-ide-continue
      :desc "resume"              "r" #'claude-code-ide-resume
      :desc "list sessions"       "l" #'claude-code-ide-list-sessions
      :desc "menu"                "m" #'claude-code-ide-menu))))
