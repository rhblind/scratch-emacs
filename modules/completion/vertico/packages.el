;;; modules/completion/vertico/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(straight-use-package 'vertico)
(straight-use-package 'orderless)
(straight-use-package 'marginalia)
(straight-use-package 'consult)
(straight-use-package 'embark)
(straight-use-package 'embark-consult)
;; wgrep makes consult-grep / consult-ripgrep results editable in
;; place via embark-export -> wgrep-change-to-wgrep-mode.
(straight-use-package 'wgrep)
