;;; modules/lang/markdown/config.el -*- lexical-binding: t; -*-
;;
;; Sensible defaults for [[https://jblevins.org/projects/markdown-mode/][markdown-mode]]: visual line wrapping, code-block
;; syntax highlighting, scaled heading faces. `:ui fonts' already
;; auto-enables `mixed-pitch-mode' in `markdown-mode' / `gfm-mode' so
;; body text gets the variable-pitch treatment.

(use-package markdown-mode
  ;; .markdown / .md / .mdx via the auto-mode-alist that ships with the
  ;; package; we just register a default association for GitHub-flavored
  ;; markdown on README files.
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :hook ((markdown-mode . visual-line-mode)
         (gfm-mode      . visual-line-mode))
  :init
  ;; Highlight code blocks per their declared language (` ```python`,
  ;; etc.) instead of leaving them as plain text.
  (setq markdown-fontify-code-blocks-natively t
        ;; `:` for tables; bare URLs become clickable links.
        markdown-enable-math nil
        markdown-italic-underscore t
        markdown-asymmetric-header t
        ;; GH default: open the previewed document in the browser
        ;; rather than relying on a bundled HTML viewer.
        markdown-command "pandoc"))

;; Heading face polish ported from the user's Doom config: scaled
;; h1..h6 with weight tapering off at deeper levels.
(with-eval-after-load 'markdown-mode
  (set-face-attribute 'markdown-header-delimiter-face nil
                      :height 0.9)
  (dolist (spec '((markdown-header-face-1 bold 1.25)
                  (markdown-header-face-2 bold 1.15)
                  (markdown-header-face-3 bold 1.12)
                  (markdown-header-face-4 semi-bold 1.09)
                  (markdown-header-face-5 semi-bold 1.06)
                  (markdown-header-face-6 semi-bold 1.03)))
    (cl-destructuring-bind (face weight height) spec
      (set-face-attribute face nil
                          :weight  weight
                          :height  height
                          :inherit 'markdown-header-face))))

;; mixed-pitch ships `org-table' in `mixed-pitch-fixed-pitch-faces' but
;; misses `markdown-table-face' and friends -- so in mixed-pitch'd
;; markdown buffers, table pipes drift out of alignment. Pin them.
(with-eval-after-load 'mixed-pitch
  (dolist (face '(markdown-table-face
                  markdown-pre-face
                  markdown-hr-face))
    (add-to-list 'mixed-pitch-fixed-pitch-faces face)))
