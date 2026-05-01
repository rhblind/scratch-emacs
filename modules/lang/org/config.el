;;; modules/lang/org/config.el -*- lexical-binding: t; -*-
;;
;; Pretty org-mode defaults: typography, visual line wrapping, hidden
;; emphasis markers, plus org-modern for modernized bullets and blocks.

(defvar scratch-org-font-scale 1.15
  "Buffer-local default-face height multiplier in org-mode buffers.
Set to nil or 1.0 to keep org at the global font size. Override by
`setq' BEFORE calling `scratch!'.")

(defun scratch-org--scale-buffer-text ()
  "Apply `scratch-org-font-scale' to the current buffer's default face."
  (when (and scratch-org-font-scale
             (numberp scratch-org-font-scale)
             (not (= 1 scratch-org-font-scale)))
    (face-remap-add-relative 'default :height scratch-org-font-scale)))

(defun scratch-org--apply-heading-faces (&rest _)
  "Scale Org heading faces by level and keep them in fixed-pitch."
  (set-face-attribute 'org-document-title nil
                      :inherit 'fixed-pitch :weight 'bold :height 1.5)
  (dolist (n '(1 2 3 4 5 6 7 8))
    (set-face-attribute (intern (format "org-level-%d" n)) nil
                        :inherit 'fixed-pitch
                        :weight (cond ((<= n 2) 'bold)
                                      ((<= n 4) 'semi-bold)
                                      (t 'normal))
                        :height 1.2)))

(use-package org
  :defer t
  :hook ((org-mode . visual-line-mode)
         (org-mode . scratch-org--scale-buffer-text)
         (org-mode . scratch-org--apply-heading-faces))
  :init
  (setq org-confirm-babel-evaluate nil
        org-babel-tangle-use-default-file-name nil
        org-hide-emphasis-markers t
        org-pretty-entities t)
  :config
  ;; Emacs 30+: keep wrapped lines visually indented by their list/heading prefix.
  (when (fboundp 'visual-wrap-prefix-mode)
    (add-hook 'org-mode-hook #'visual-wrap-prefix-mode)))

(use-package org-modern
  :hook ((org-mode            . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :init
  (setq org-modern-hide-stars "  ")
  :config
  (setq org-modern-fold-stars
        '(("◉" . "◯")
          ("│" . "└")
          (" │" . " └")
          (" │" . " └"))))
