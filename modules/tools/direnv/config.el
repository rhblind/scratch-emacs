;;; modules/tools/direnv/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/purcell/envrc][envrc.el]]: per-buffer hook into the `direnv' CLI. Whenever a buffer
;; visits a file under a directory with a trusted `.envrc', envrc
;; runs `direnv export json' in that dir and applies the result to the
;; buffer's local `process-environment'. Unlike a global env mutation,
;; this scopes correctly per-project: open two projects in different
;; frames and each gets its own env.
;;
;; Pairs with `:tools mise' (load both: direnv handles `.envrc',
;; mise handles `mise.toml' / `.tool-versions'). They don't overlap.
;;
;; Requires the `direnv' binary on PATH. envrc itself is pure elisp.

(use-package envrc
  :defer t
  :hook (after-init . envrc-global-mode)
  :config
  ;; Quiet success messages -- the modeline indicator is enough.
  (setq envrc-show-summary-in-minibuffer nil))
