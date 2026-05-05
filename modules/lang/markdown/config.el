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

;;;; Localleader bindings (`,' in markdown buffers)
;;
;; Mirrors the org-mode localleader where markdown-mode provides
;; equivalent functionality. Key positions match org's so muscle memory
;; carries over between the two modes.

(when (modulep! :editor leader)
  (with-eval-after-load 'markdown-mode
    (map! :map markdown-mode-map :localleader
      :desc "edit code block"        "'" #'markdown-edit-code-block
      :desc "insert list item"       "-" #'markdown-insert-list-item
      :desc "export"                 "e" #'markdown-export
      :desc "footnote"              "f" #'markdown-insert-footnote
      :desc "insert header"          "h" #'markdown-insert-header-dwim
      :desc "preview"                "p" #'markdown-preview
      :desc "toggle checkbox"        "x" #'markdown-toggle-gfm-checkbox
      :desc "do (dwim)"             "RET" #'markdown-do
      ;; -- emphasis / text formatting (mirrors org `, X') --
      (:prefix-map ("X" . "emphasis")
       :desc "bold"                  "b" #'markdown-insert-bold
       :desc "italic"               "i" #'markdown-insert-italic
       :desc "code"                 "c" #'markdown-insert-code
       :desc "strikethrough"        "s" #'markdown-insert-strike-through
       :desc "kbd"                  "k" #'markdown-insert-kbd)
      ;; -- insert --
      (:prefix-map ("i" . "insert")
       :desc "code block"           "c" #'markdown-insert-gfm-code-block
       :desc "blockquote"           "b" #'markdown-insert-blockquote
       :desc "footnote"             "f" #'markdown-insert-footnote
       :desc "horizontal rule"      "h" #'markdown-insert-hr
       :desc "foldable block"       "F" #'markdown-insert-foldable-block
       :desc "image"                "i" #'markdown-insert-image
       :desc "table"                "t" #'markdown-table-insert-column)
      ;; -- links (mirrors org `, l') --
      (:prefix-map ("l" . "links")
       :desc "insert link"          "l" #'markdown-insert-link
       :desc "insert image"         "i" #'markdown-insert-image
       :desc "toggle url hiding"    "t" #'markdown-toggle-url-hiding)
      ;; -- tables (mirrors org `, b') --
      (:prefix-map ("b" . "tables")
       :desc "align"                "a" #'markdown-table-align
       :desc "sort lines"           "s" #'markdown-table-sort-lines
       :desc "transpose"            "t" #'markdown-table-transpose
       :desc "convert region"       "c" #'markdown-table-convert-region
       (:prefix-map ("d" . "delete")
        :desc "column"              "c" #'markdown-table-delete-column
        :desc "row"                 "r" #'markdown-table-delete-row)
       (:prefix-map ("i" . "insert")
        :desc "column"              "c" #'markdown-table-insert-column
        :desc "row"                 "r" #'markdown-table-insert-row)
       (:prefix-map ("m" . "move")
        :desc "column left"         "h" #'markdown-table-move-column-left
        :desc "column right"        "l" #'markdown-table-move-column-right
        :desc "row up"              "k" #'markdown-table-move-row-up
        :desc "row down"            "j" #'markdown-table-move-row-down))
      ;; -- tree / subtree (mirrors org `, s') --
      (:prefix-map ("s" . "tree/subtree")
       :desc "promote"              "h" #'markdown-promote-subtree
       :desc "move down"            "j" #'markdown-move-subtree-down
       :desc "move up"              "k" #'markdown-move-subtree-up
       :desc "demote"               "l" #'markdown-demote-subtree
       :desc "narrow"               "n" #'markdown-narrow-to-subtree
       :desc "widen"                "w" #'widen
       :desc "narrow to block"      "b" #'markdown-narrow-to-block))
))
