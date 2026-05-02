;;; modules/ui/smooth-scroll/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; ultra-scroll lives on GitHub only (not MELPA), so we need an explicit recipe.
(straight-use-package
 '(ultra-scroll :type git :host github :repo "jdtsmith/ultra-scroll"
                :files ("*.el")))

;; +interpolate adds good-scroll for keyboard-triggered scrolling
;; (C-v / M-v / evil-scroll-up / -down). ultra-scroll handles the wheel.
(when (modulep! +interpolate)
  (straight-use-package 'good-scroll))
