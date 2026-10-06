;;; modules/tools/dape/config.el -*- lexical-binding: t; -*-
;;
;; dape: Debug Adapter Protocol client. Kept deliberately thin: dape's
;; defaults (gud-style `C-x C-a' prefix, gud window arrangement, repeat
;; mode friendliness) are all reasonable, and the info / REPL buffers
;; get vim bindings via evil-collection when `:editor evil +everywhere'
;; is on -- nothing to wire here.
;;
;; What language modules DO provide under their own `+debug' flag
;; (gated on `(modulep! :tools dape)'):
;;
;;   - adapter configs appended to `dape-configs' (upstream entries are
;;     never clobbered; language-specific variants get their own name,
;;     e.g. `debugpy-uv'),
;;
;;   - localleader `d' bindings in the language's major mode map.
;;
;; Session flow: `M-x dape' (or the language's localleader binding)
;; prompts for a config name from `dape-configs'; extra config fields
;; can be edited inline at the prompt.

(use-package dape
  :commands (dape dape-repl dape-info dape-quit dape-kill dape-disconnect-quit
             dape-restart dape-breakpoint-toggle dape-breakpoint-remove-all
             dape-next dape-step-in dape-step-out dape-continue dape-pause))
