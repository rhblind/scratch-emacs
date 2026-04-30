;;; modules/ui/theme/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Rougier's nano-theme isn't on MELPA, so pull it straight from the repo.
(straight-use-package
 '(nano-theme :type git :host github :repo "rougier/nano-theme"))

;; auto-dark drives the default behavior (follow OS appearance). Skip the
;; install only when the user has explicitly opted into a static theme.
(unless (or (modulep! +light) (modulep! +dark))
  (straight-use-package 'auto-dark))
