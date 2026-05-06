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

;; Defensive: `outline-map-region' (C built-in in Emacs 30) signals
;; `wrong-type-argument: number-or-marker-p, nil' during
;; `revert-buffer' in modes where outshine's outline-regexp doesn't
;; match (e.g. json-ts-mode). The nil can come from the outer args
;; OR from internal position calculations in the C code. Guard args
;; AND catch the internal error so the revert completes cleanly.
(advice-add 'outline-map-region :around
            (lambda (orig fn beg end)
              (when (and (number-or-marker-p beg)
                         (number-or-marker-p end))
                (condition-case nil
                    (funcall orig fn beg end)
                  (wrong-type-argument nil)))))
