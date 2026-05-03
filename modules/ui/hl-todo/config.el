;;; modules/ui/hl-todo/config.el -*- lexical-binding: t; -*-
;;
;; Highlight keywords like TODO / FIXME / NOTE in comments via [[https://github.com/tarsius/hl-todo][hl-todo]].
;; The keyword set and conventions are copied from Doom's :ui hl-todo so
;; comments look the same to anyone coming from a Doom config.

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :hook (yaml-mode . hl-todo-mode)
  :hook (conf-mode . hl-todo-mode)
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        '(;; A reminder to change or add something at a later date.
          ("TODO" warning bold)
          ;; Code (or code paths) that's broken, unimplemented, or slow,
          ;; and may become a bigger problem later.
          ("FIXME" error bold)
          ;; Code that needs to be revisited, either to upstream it,
          ;; improve it, or address non-critical issues.
          ("REVIEW" font-lock-keyword-face bold)
          ;; Code smells where questionable practices are used
          ;; intentionally, and/or are likely to break in a future update.
          ("HACK" font-lock-constant-face bold)
          ;; Code that's about to be removed (the code, not necessarily
          ;; the feature it enables).
          ("DEPRECATED" font-lock-doc-face bold)
          ;; Extra keywords commonly found in the wild; project-specific
          ;; meaning varies.
          ("NOTE" success bold)
          ("BUG" error bold)
          ("WARN" warning bold)
          ("XXX" font-lock-constant-face bold))))

;; consult-todo: project-wide TODO picker via consult. Bound under
;; the search prefix so it lives next to `consult-line', `consult-imenu',
;; etc. owned by `:completion vertico'.
(when (modulep! :completion vertico)
  (use-package consult-todo
    :defer t
    :commands (consult-todo consult-todo-project)
    :init
    (when (modulep! :editor leader)
      (map! :leader
        :desc "search todos (buffer)"  "s t" #'consult-todo
        :desc "search todos (project)" "s T" #'consult-todo-project))))
