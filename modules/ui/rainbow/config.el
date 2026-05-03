;;; modules/ui/rainbow/config.el -*- lexical-binding: t; -*-
;;
;; rainbow-mode: colorize CSS color literals (e.g. `#ff7f50',
;; `rgb(255, 127, 80)', `coral') with their actual color so editing
;; theme files / stylesheets feels less like guessing. Activates
;; lazily in stylesheet-flavored modes; toggle elsewhere with
;; `M-x rainbow-mode'.

(use-package rainbow-mode
  :commands rainbow-mode
  :hook ((css-mode         . rainbow-mode)
         (css-ts-mode      . rainbow-mode)
         (scss-mode        . rainbow-mode)
         (less-css-mode    . rainbow-mode)
         (web-mode         . rainbow-mode)
         (html-mode        . rainbow-mode)
         (mhtml-mode       . rainbow-mode)
         (emacs-lisp-mode  . rainbow-mode)
         (lisp-data-mode   . rainbow-mode)
         (conf-mode        . rainbow-mode)))
