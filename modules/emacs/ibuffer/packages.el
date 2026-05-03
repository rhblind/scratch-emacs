;;; modules/emacs/ibuffer/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; ibuffer-vc: group / sort buffers by their VCS root and show
;; per-buffer git status in a column. Lighter-weight than the
;; projectile-flavoured equivalent and works with the framework's
;; project.el setup (the "VC root" is the same dir project.el
;; reports as the project root in any git repo).
(straight-use-package 'ibuffer-vc)
