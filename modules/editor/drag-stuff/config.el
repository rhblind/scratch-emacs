;;; modules/editor/drag-stuff/config.el -*- lexical-binding: t; -*-
;;
;; Move the current line / region up / down (or word left / right) with
;; modifier+arrow. Bindings: M-<up> / M-<down> / M-<left> / M-<right>
;; in non-evil + evil insert; if you'd rather have C-<up> / C-<down>,
;; rebind in your config.

(use-package drag-stuff
  :defer t
  :commands (drag-stuff-mode drag-stuff-global-mode
             drag-stuff-up drag-stuff-down
             drag-stuff-left drag-stuff-right)
  :hook (find-file . drag-stuff-global-mode)
  :config
  ;; drag-stuff's default keymap binds M-<up>/<down>/<left>/<right>.
  ;; It refuses to activate in some major modes (org, where it
  ;; conflicts with `org-metaup' / `org-metadown') -- already in
  ;; `drag-stuff-except-modes'. Bind `org-metaup' / `org-metadown'
  ;; etc. as usual in those buffers.
  (drag-stuff-define-keys))
