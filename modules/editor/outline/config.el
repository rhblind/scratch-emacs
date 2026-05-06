;;; modules/editor/outline/config.el -*- lexical-binding: t; -*-
;;
;; Built-in `outline-minor-mode' for comment-prefixed heading folding
;; and navigation in prog/text buffers. Recognises `;;; foo' / `# bar'
;; etc. TAB cycles a subtree, S-TAB cycles globally.
;;
;; Uses Emacs 30's native `outline-minor-mode-cycle' and
;; `outline-minor-mode-highlight'. `consult-outline' (SPC s o) serves
;; as the heading picker.

(setq outline-minor-mode-cycle t
      outline-minor-mode-highlight 'override)

(add-hook 'prog-mode-hook #'outline-minor-mode)

(defun scratch-outline--maybe-enable ()
  "Enable `outline-minor-mode' in text-mode buffers, except org-mode."
  (unless (derived-mode-p 'org-mode)
    (outline-minor-mode 1)))

(add-hook 'text-mode-hook #'scratch-outline--maybe-enable)

;; Scale outline heading faces to match org/markdown heading styling.
(with-eval-after-load 'outline
  (dolist (spec '((outline-1 extra-bold 1.25)
                  (outline-2 bold       1.15)
                  (outline-3 bold       1.12)
                  (outline-4 semi-bold  1.09)
                  (outline-5 semi-bold  1.06)
                  (outline-6 semi-bold  1.03)
                  (outline-7 semi-bold  1.01)
                  (outline-8 semi-bold  1.0)))
    (set-face-attribute (car spec) nil
                        :weight (cadr spec)
                        :height (caddr spec))))
