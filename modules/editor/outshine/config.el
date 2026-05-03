;;; modules/editor/outshine/config.el -*- lexical-binding: t; -*-
;;
;; outshine: org-mode-style folding / navigation in non-org modes,
;; built on top of `outline-minor-mode'. Recognises comment-prefixed
;; headings (`;;; foo' / `;;;; bar' in elisp, `# foo' / `## bar' in
;; conf / shell, etc.) so you can `TAB' to fold a section and
;; `M-RET' to insert a sibling heading.
;;
;; Auto-enabled in `prog-mode'. Toggle with `M-x outline-minor-mode'.

(use-package outshine
  :hook ((prog-mode . outshine-mode)
         (outline-minor-mode . outshine-mode))
  :init
  ;; Use the same fold cycling style as org-mode: TAB cycles current
  ;; subtree, S-TAB cycles all.
  (setq outshine-use-speed-commands t))
