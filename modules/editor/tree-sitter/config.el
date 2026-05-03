;;; modules/editor/tree-sitter/config.el -*- lexical-binding: t; -*-
;;
;; treesit-auto: detect installed tree-sitter grammars and remap the
;; matching legacy major modes to their `<lang>-ts-mode' equivalents.
;; On Emacs 29+ this gets you better syntax highlighting, indentation,
;; and structural editing across most languages with no per-language
;; config needed.

(use-package treesit-auto
  :demand t
  :custom
  ;; Prompt before installing a grammar (instead of installing silently
  ;; on every new language file). Set to t to install on demand without
  ;; asking, or nil to never auto-install.
  (treesit-auto-install 'prompt)
  :config
  ;; PERF: pre-compute the list of available grammars once at startup
  ;; instead of probing on every `set-auto-mode' call. Without this,
  ;; opening files measurably slows down on systems with many grammars.
  (setq treesit-auto-langs
        (cl-loop for recipe in treesit-auto-recipe-list
                 when (treesit-language-available-p
                       (treesit-auto-recipe-lang recipe))
                 collect (treesit-auto-recipe-lang recipe)))
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
