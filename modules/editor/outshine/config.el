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

;; Defensive: `outline-map-region' (built-in `outline.el') signals
;; `Wrong type argument: number-or-marker-p, nil' when called with
;; nil for BEG / END. That can happen during `revert-buffer' when
;; outshine's `outline-minor-mode-hook' re-applies in a buffer
;; where the outline structure hasn't yet been recomputed -- the
;; result is a noisy stack trace on every revert, but the revert
;; itself succeeds. Wrap with a guard so the call is a no-op when
;; either bound is nil.
(advice-add 'outline-map-region :around
            (lambda (orig fn beg end)
              (when (and (number-or-marker-p beg)
                         (number-or-marker-p end))
                (funcall orig fn beg end))))
