;;; modules/lang/org/config.el -*- lexical-binding: t; -*-
;;
;; Pretty org-mode defaults: typography, visual line wrapping, hidden
;; emphasis markers, indented headings, and org-appear for editing.

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
  ;; Use Emacs's built-in org. Pulling org from straight while init.el
  ;; already loaded built-in org (via the tangle step) produces a
  ;; version-mismatch warning and a half-loaded state. org-appear and
  ;; org-superstar stack on top of built-in org without trouble.
  :straight nil
  :defer t
  :hook ((org-mode . visual-line-mode)
         (org-mode . scratch-org--scale-buffer-text)
         (org-mode . scratch-org--apply-heading-faces)
         (org-mode . (lambda () (setq-local tab-width 8)))
         (org-mode . (lambda () (setq-local line-spacing 0.2)))
         (org-mode . (lambda () (display-line-numbers-mode -1))))
  ;; Stock-Emacs global shortcuts for the three top-level org entry
  ;; points (`C-c a' agenda, `C-c c' capture, `C-c l' store-link).
  ;; Available everywhere, not just in org buffers.
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c l" . org-store-link))
  :init
  (setq org-confirm-babel-evaluate nil
        org-babel-tangle-use-default-file-name nil
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-ellipsis " …"
        org-startup-indented t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-src-window-setup 'current-window)
  :config
  ;; Hide property drawers on open (they stay visible when
  ;; org-startup-folded is showeverything).
  (add-hook 'org-mode-hook
            (lambda () (org-cycle-hide-drawers 'all)))

  ;; Restore the easy-template expansion: `<s' + TAB inserts a `#+begin_src'
  ;; block, `<q' a quote, `<e' an example, etc. Org 9.2 (bundled with
  ;; Emacs 27+) extracted these into a separate `org-tempo' library and
  ;; stopped loading it by default; this re-enables them.
  (require 'org-tempo)
  (require 'org-mouse)

  ;; When tangling, add comments linking back to the org source.
  (setf (alist-get :comment org-babel-default-header-args) "link")

  ;; Enable Graphviz DOT blocks (`#+begin_src dot').
  (add-to-list 'org-babel-load-languages '(dot . t))
  (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)

  ;; Italic quote and verse blocks.
  (setq org-fontify-quote-and-verse-blocks t)

  ;; Deadline faces: escalate from distant to overdue.
  (setq org-agenda-deadline-faces
        '((1.001 . error)
          (1.0   . org-warning)
          (0.5   . org-upcoming-deadline)
          (0.0   . org-upcoming-distant-deadline)))

  ;; Prettify org keywords and markers with Unicode glyphs.
  (add-hook 'org-mode-hook #'scratch-org--setup-prettify-symbols))

(defun scratch-org--setup-prettify-symbols ()
  "Set `prettify-symbols-alist' for org-mode and enable the mode."
  (setq-local prettify-symbols-alist
              (append
               '(("[ ]"             . ?☐)
                 ("[-]"             . ?◼)
                 ("[X]"             . ?☑)
                 ("#+title:"        . ?§)
                 ("#+subtitle:"     . ?¶)
                 ("#+author:"       . ?◇)
                 ("#+date:"         . ?◆)
                 ("#+property:"     . ?☸)
                 ("#+options:"      . ?⌥)
                 ("#+startup:"      . ?⏻)
                 ("#+macro:"        . ?⊞)
                 ("#+begin_quote"   . ?❝)
                 ("#+end_quote"     . ?❞)
                 ("#+begin_export"  . ?⏩)
                 ("#+end_export"    . ?⏪)
                 ("#+caption:"      . ?☰)
                 ("#+header:"       . ?›)
                 ("#+RESULTS:"      . ?⇒)
                 (":PROPERTIES:"    . ?⚙)
                 (":END:"           . ?∎))
               prettify-symbols-alist))
  (prettify-symbols-mode 1))

(defun scratch-org/indent-src-block ()
  "Indent the source block at point."
  (interactive)
  (when (org-in-src-block-p)
    (org-edit-special)
    (indent-region (point-min) (point-max))
    (org-edit-src-exit)))
(defalias 'org-indent-src-block #'scratch-org/indent-src-block)
(with-eval-after-load 'ob-core
  (define-key org-babel-map "F" #'org-indent-src-block))

;;;; Emphasis commands

(defmacro scratch-org--def-emphasize (name char)
  "Define an interactive command NAME that calls `org-emphasize' with CHAR."
  `(defun ,name () (interactive) (org-emphasize ,char)))

(scratch-org--def-emphasize scratch-org/emphasize-bold          ?*)
(scratch-org--def-emphasize scratch-org/emphasize-italic        ?/)
(scratch-org--def-emphasize scratch-org/emphasize-code          ?~)
(scratch-org--def-emphasize scratch-org/emphasize-verbatim      ?=)
(scratch-org--def-emphasize scratch-org/emphasize-strikethrough ?+)
(scratch-org--def-emphasize scratch-org/emphasize-underline     ?_)
(scratch-org--def-emphasize scratch-org/emphasize-clear         ?\s)

;; org-appear: reveal hidden emphasis markers (the surrounding `*' / `/'
;; / `=' / `~' that org-mode normally hides) when the cursor lands on
;; them, so editing emphasized regions doesn't feel like working blind.
;; Pairs with `org-hide-emphasis-markers t' set above.
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :init
  (setq org-appear-autoemphasis  t      ; *bold*, /italic/, =verbatim=, ~code~, +strike+
        org-appear-autosubmarkers t     ; sub_script, super^script
        org-appear-autolinks      nil)) ; leave [[link][text]] folded

;; org-superstar: replace heading stars with cleaner Unicode bullets.
;; Compatible with org-indent-mode.
(use-package org-superstar
  :hook (org-mode . org-superstar-mode)
  :init
  (setq org-superstar-headline-bullets-list '("◉" "○" "◈" "◇" "▸")
        org-superstar-leading-bullet ?\s
        org-superstar-special-todo-items t))

;; org-pretty-table: redraw org tables with Unicode box-drawing characters.
(use-package org-pretty-table
  :hook (org-mode . org-pretty-table-mode))

;; Auto-pair `<<...>>' (org radio-target syntax) when smartparens is
;; enabled. Insert-only -- doesn't try to wrap regions or balance on
;; delete, so non-target uses of `<' aren't disturbed.
(when (modulep! :editor smartparens)
  (with-eval-after-load 'smartparens
    (sp-local-pair '(org-mode) "<<" ">>" :actions '(insert))))

;; +hugo: export org subtrees as Hugo blog posts via ox-hugo.
;; Set `org-hugo-base-dir' in your user config to point at the Hugo
;; site root (e.g. "~/workspace/hugo-blog").
(when (modulep! +hugo)
  (use-package ox-hugo
    :after ox))

;; org-cliplink: insert the URL on the kill ring as an org link with
;; the page's title fetched live. Useful inside captures where you've
;; just yanked a URL from the browser. Override `transport-implementation'
;; in your config if you'd rather not shell out to curl.
(use-package org-cliplink
  :commands (org-cliplink org-cliplink-capture))

;; org-download: drag-and-drop / paste images straight from the
;; clipboard into org buffers; files land under
;; `<org-directory>/images/' by default. Override `org-download-image-dir'
;; in your config to relocate.
(use-package org-download
  :hook (org-mode . org-download-enable)
  :init
  (with-eval-after-load 'org
    (unless (boundp 'org-download-image-dir)
      (setq org-download-image-dir
            (expand-file-name "images" org-directory)))
    (setq org-download-heading-lvl nil
          ;; Sensible system-default screenshot helper.
          org-download-screenshot-method
          (cond ((eq system-type 'darwin) "screencapture -i %s")
                (t                        "import %s")))))

;;;; Localleader bindings (`,' in org buffers)
;;
;; Full transcription of Doom's :lang org localleader, with Doom helper
;; functions (`+org/...') skipped where we don't have equivalents. The
;; prefix names and key positions match Doom's so muscle memory carries
;; over. Skipped Doom helpers are listed in a comment near each prefix.

(when (modulep! :editor leader)
  (with-eval-after-load 'org
    (map! :map org-mode-map :localleader
      :desc "update stats cookies"  "#" #'org-update-statistics-cookies
      :desc "edit special block"    "'" #'org-edit-special
      :desc "headline (C-c *)"      "*" #'org-ctrl-c-star
      :desc "list (C-c -)"          "-" #'org-ctrl-c-minus
      :desc "switchb"               "," #'org-switchb
      :desc "goto"                  "." #'org-goto
      :desc "cite insert"           "@" #'org-cite-insert
      :desc "archive subtree"       "A" #'org-archive-subtree-default
      :desc "export dispatch"       "e" #'org-export-dispatch
      :desc "footnote"              "f" #'org-footnote-action
      :desc "toggle heading"        "h" #'org-toggle-heading
      :desc "toggle item"           "i" #'org-toggle-item
      :desc "create / get id"       "I" #'org-id-get-create
      :desc "babel"                 "v" org-babel-map
      :desc "remove babel result"   "k" #'org-babel-remove-result
      :desc "store link"            "n" #'org-store-link
      :desc "set property"          "o" #'org-set-property
      :desc "set tags"              "q" #'org-set-tags-command
      :desc "todo state"            "t" #'org-todo
      :desc "todo list"             "T" #'org-todo-list
      "x" nil
      :desc "toggle checkbox"       "X" #'org-toggle-checkbox
      ;; -- attachments (skipped: +org/find-file-in-attachments,
      ;;    +org/attach-file-and-insert-link, org-download-*) --
      (:prefix-map ("a" . "attachments")
       :desc "attach"               "a" #'org-attach
       :desc "delete one"           "d" #'org-attach-delete-one
       :desc "delete all"           "D" #'org-attach-delete-all
       :desc "new"                  "n" #'org-attach-new
       :desc "open"                 "o" #'org-attach-open
       :desc "open in emacs"        "O" #'org-attach-open-in-emacs
       :desc "reveal"               "r" #'org-attach-reveal
       :desc "reveal in emacs"      "R" #'org-attach-reveal-in-emacs
       :desc "url"                  "u" #'org-attach-url
       :desc "set directory"        "s" #'org-attach-set-directory
       :desc "sync"                 "S" #'org-attach-sync)
      ;; -- tables --
      (:prefix-map ("b" . "tables")
       :desc "insert hline"         "-" #'org-table-insert-hline
       :desc "align"                "a" #'org-table-align
       :desc "blank field"          "b" #'org-table-blank-field
       :desc "create / convert"     "c" #'org-table-create-or-convert-from-region
       :desc "edit field"           "e" #'org-table-edit-field
       :desc "edit formulas"        "f" #'org-table-edit-formulas
       :desc "field info"           "h" #'org-table-field-info
       :desc "sort lines"           "s" #'org-table-sort-lines
       :desc "recalculate"          "r" #'org-table-recalculate
       :desc "recalculate buffer"   "R" #'org-table-recalculate-buffer-tables
       (:prefix-map ("d" . "delete")
        :desc "column"              "c" #'org-table-delete-column
        :desc "row"                 "r" #'org-table-kill-row)
       (:prefix-map ("i" . "insert")
        :desc "column"              "c" #'org-table-insert-column
        :desc "hline"               "h" #'org-table-insert-hline
        :desc "row"                 "r" #'org-table-insert-row
        :desc "hline & move"        "H" #'org-table-hline-and-move)
       (:prefix-map ("t" . "toggle")
        :desc "formula debugger"    "f" #'org-table-toggle-formula-debugger
        :desc "coord overlays"      "o" #'org-table-toggle-coordinate-overlays))
      ;; -- clock (skipped: +org/toggle-last-clock, the cmd! `G' variant) --
      (:prefix-map ("c" . "clock")
       :desc "cancel"               "c" #'org-clock-cancel
       :desc "mark default task"    "d" #'org-clock-mark-default-task
       :desc "modify effort"        "e" #'org-clock-modify-effort-estimate
       :desc "set effort"           "E" #'org-set-effort
       :desc "goto"                 "g" #'org-clock-goto
       :desc "in"                   "i" #'org-clock-in
       :desc "in last"              "I" #'org-clock-in-last
       :desc "out"                  "o" #'org-clock-out
       :desc "resolve"              "r" #'org-resolve-clocks
       :desc "report"               "R" #'org-clock-report
       :desc "evaluate range"       "t" #'org-evaluate-time-range
       :desc "stamp up"             "=" #'org-clock-timestamps-up
       :desc "stamp down"           "-" #'org-clock-timestamps-down)
      ;; -- date / deadline --
      (:prefix-map ("d" . "date/deadline")
       :desc "deadline"             "d" #'org-deadline
       :desc "schedule"             "s" #'org-schedule
       :desc "time stamp"           "t" #'org-time-stamp
       :desc "inactive stamp"       "T" #'org-time-stamp-inactive)
      ;; -- goto (skipped: +org/goto-visible) --
      (:prefix-map ("g" . "goto")
       :desc "goto"                 "g" #'org-goto
       :desc "clock"                "c" #'org-clock-goto
       :desc "id"                   "i" #'org-id-goto
       :desc "refile last stored"   "r" #'org-refile-goto-last-stored
       :desc "capture last stored"  "x" #'org-capture-goto-last-stored)
      ;; -- links (skipped: +org/remove-link, +org/yank-link, org-cliplink, org-mac-link) --
      (:prefix-map ("l" . "links")
       :desc "id store link"        "i" #'org-id-store-link
       :desc "insert link"          "l" #'org-insert-link
       :desc "insert all links"     "L" #'org-insert-all-links
       :desc "store link"           "s" #'org-store-link
       :desc "insert last stored"   "S" #'org-insert-last-stored-link
       :desc "toggle link display"  "t" #'org-toggle-link-display)
      ;; -- publish --
      (:prefix-map ("P" . "publish")
       :desc "all"                  "a" #'org-publish-all
       :desc "current file"         "f" #'org-publish-current-file
       :desc "publish"              "p" #'org-publish
       :desc "current project"      "P" #'org-publish-current-project
       :desc "sitemap"              "s" #'org-publish-sitemap)
      ;; -- refile (skipped: +org/refile-to-* helpers) --
      (:prefix-map ("r" . "refile")
       :desc "refile"               "r" #'org-refile
       :desc "refile reverse"       "R" #'org-refile-reverse)
      ;; -- tree / subtree --
      (:prefix-map ("s" . "tree/subtree")
       :desc "toggle archive tag"   "a" #'org-toggle-archive-tag
       :desc "indirect buffer"      "b" #'org-tree-to-indirect-buffer
       :desc "clone with shift"     "c" #'org-clone-subtree-with-time-shift
       :desc "cut"                  "d" #'org-cut-subtree
       :desc "promote"              "h" #'org-promote-subtree
       :desc "move down"            "j" #'org-move-subtree-down
       :desc "move up"              "k" #'org-move-subtree-up
       :desc "demote"               "l" #'org-demote-subtree
       :desc "narrow"               "n" #'org-narrow-to-subtree
       :desc "refile"               "r" #'org-refile
       :desc "sparse tree"          "s" #'org-sparse-tree
       :desc "widen"                "w" #'widen
       :desc "archive"              "A" #'org-archive-subtree-default
       :desc "widen"                "N" #'widen     ; Doom-default alias
       :desc "sort"                 "S" #'org-sort)
      ;; -- priority --
      (:prefix-map ("p" . "priority")
       :desc "down"                 "d" #'org-priority-down
       :desc "set"                  "p" #'org-priority
       :desc "up"                   "u" #'org-priority-up)
      ;; -- emphasis / text formatting --
      (:prefix-map ("x" . "text")
       :desc "bold"                 "b" #'scratch-org/emphasize-bold
       :desc "code"                 "c" #'scratch-org/emphasize-code
       :desc "italic"               "i" #'scratch-org/emphasize-italic
       :desc "clear"                "r" #'scratch-org/emphasize-clear
       :desc "strikethrough"        "s" #'scratch-org/emphasize-strikethrough
       :desc "underline"            "u" #'scratch-org/emphasize-underline
       :desc "verbatim"             "v" #'scratch-org/emphasize-verbatim))
    ;; Use consult-org-* when consult is available (richer picker).
    (when (modulep! :completion vertico)
      (map! :map org-mode-map :localleader
        :desc "goto heading"         "." #'consult-org-heading
        :desc "search agenda"        "/" #'consult-org-agenda
        ;; Inside the goto submenu, override `g g' / `g G' to consult variants.
        (:prefix-map ("g" . "goto")
         :desc "consult heading"    "g" #'consult-org-heading
         :desc "consult agenda"     "G" #'consult-org-agenda)))))

;;;; org-agenda localleader

;; Localleader for `org-agenda-mode' is intentionally narrow. The
;; agenda map already binds plenty of single letters directly
;; (`t' org-agenda-todo, `e' set-effort, `n'/`p' navigate, `g'/`r'
;; redo, `/' `=' `^' `<' filters, `o' open-link, etc.) -- duplicating
;; them behind `,' adds noise. Mirrors Doom's set: date/clock/priority
;; submenus plus `q' (set tags; the direct key `:' is awkward) and `r'
;; (refile; the direct key `r' is redo).
(when (modulep! :editor leader)
  (with-eval-after-load 'org-agenda
    (map! :map org-agenda-mode-map :localleader
      (:prefix-map ("d" . "date/deadline")
       :desc "deadline"             "d" #'org-agenda-deadline
       :desc "schedule"             "s" #'org-agenda-schedule)
      (:prefix-map ("c" . "clock")
       :desc "cancel"               "c" #'org-agenda-clock-cancel
       :desc "goto"                 "g" #'org-agenda-clock-goto
       :desc "in"                   "i" #'org-agenda-clock-in
       :desc "out"                  "o" #'org-agenda-clock-out
       :desc "report mode"          "r" #'org-agenda-clockreport-mode
       :desc "show issues"          "s" #'org-agenda-show-clocking-issues)
      (:prefix-map ("p" . "priority")
       :desc "down"                 "d" #'org-agenda-priority-down
       :desc "set"                  "p" #'org-agenda-priority
       :desc "up"                   "u" #'org-agenda-priority-up)
      :desc "set tags"              "q" #'org-agenda-set-tags
      :desc "refile"                "r" #'org-agenda-refile)))

;;;; DWIM at point (ported from Doom's +org/dwim-at-point)

(defun scratch-org--toggle-inline-images-in-subtree (&optional beg end)
  "Toggle inline image previews in the current subtree."
  (let* ((beg (or beg
                  (if (org-before-first-heading-p)
                      (point-min)
                    (save-excursion (org-back-to-heading) (point)))))
         (end (or end
                  (if (org-before-first-heading-p)
                      (save-excursion (org-next-visible-heading 1) (point))
                    (save-excursion (org-end-of-subtree) (point)))))
         (overlays (cl-remove-if-not (lambda (ov) (overlay-get ov 'org-image-overlay))
                                     (ignore-errors (overlays-in beg end)))))
    (if overlays
        (dolist (ov overlays)
          (delete-overlay ov)
          (setq org-inline-image-overlays (delete ov org-inline-image-overlays)))
      (org-display-inline-images nil nil beg end))))

(defun scratch-org/dwim-at-point (&optional arg)
  "Do-what-I-mean at point.
Execute src blocks, follow links, toggle checkboxes, recalculate
tables, cycle TODOs, preview LaTeX, and more."
  (interactive "P")
  (if (button-at (point))
      (call-interactively #'push-button)
    (let* ((context (org-element-context))
           (type (org-element-type context)))
      (while (and context (memq type '(verbatim code bold italic underline
                                        strike-through subscript superscript)))
        (setq context (org-element-property :parent context)
              type (org-element-type context)))
      (pcase type
        ((or `citation `citation-reference)
         (org-cite-follow context arg))
        (`headline
         (cond ((org-element-property :todo-type context)
                (org-todo (if (eq (org-element-property :todo-type context) 'done)
                              'todo 'done)))
               (t (org-update-checkbox-count)
                  (org-update-parent-todo-statistics)
                  (scratch-org--toggle-inline-images-in-subtree))))
        (`clock (org-clock-update-time-maybe))
        (`footnote-reference
         (org-footnote-goto-definition (org-element-property :label context)))
        (`footnote-definition
         (org-footnote-goto-previous-reference (org-element-property :label context)))
        ((or `planning `timestamp) (org-follow-timestamp-link))
        ((or `table `table-row)
         (if (org-at-TBLFM-p)
             (org-table-calc-current-TBLFM)
           (ignore-errors
             (save-excursion
               (goto-char (org-element-property :contents-begin context))
               (org-call-with-arg 'org-table-recalculate (or arg t))))))
        (`table-cell
         (org-table-blank-field)
         (org-table-recalculate arg)
         (when (and (string-empty-p (string-trim (org-table-get-field)))
                    (bound-and-true-p evil-local-mode))
           (evil-change-state 'insert)))
        (`babel-call (org-babel-lob-execute-maybe))
        (`statistics-cookie
         (save-excursion (org-update-statistics-cookies arg)))
        ((or `src-block `inline-src-block)
         (org-babel-execute-src-block arg))
        ((or `latex-fragment `latex-environment)
         (org-latex-preview arg))
        (`link
         (let* ((lineage (org-element-lineage context '(link) t))
                (path (org-element-property :path lineage)))
           (if (and path (image-supported-file-p path))
               (scratch-org--toggle-inline-images-in-subtree
                (org-element-property :begin lineage)
                (org-element-property :end lineage))
             (org-open-at-point arg))))
        ((guard (org-element-property :checkbox
                  (org-element-lineage context '(item) t)))
         (org-toggle-checkbox))
        (_ (if (or (org-in-regexp org-ts-regexp-both nil t)
                   (org-in-regexp org-tsr-regexp-both nil t)
                   (org-in-regexp org-link-any-re nil t))
               (call-interactively #'org-open-at-point)
             (scratch-org--toggle-inline-images-in-subtree)))))))

(defun scratch-org/return ()
  "Call `org-return' with electric indent."
  (interactive)
  (org-return electric-indent-mode))

(defun scratch-org/shift-return (&optional arg)
  "Insert a literal newline, or copy-down in tables."
  (interactive "p")
  (if (org-at-table-p)
      (org-table-copy-down arg)
    (org-return nil arg)))

;;;; evil integration
;;
;; Vim-style heading / list / table motion + per-buffer insert-state
;; defaults in org-capture, plus dedicated `evil-org-agenda-mode' so
;; the agenda buffer respects evil keys (j/k navigate, etc.).
;; evil-collection's org support is less thorough than this package.

(when (modulep! :editor evil)
  (use-package evil-org
    :hook (org-mode        . evil-org-mode)
    ;; Capture buffers open in insert state so you can start typing.
    :hook (org-capture-mode . evil-insert-state)
    :init
    ;; Visual selection survives an outline shift (>>, <<).
    (setq evil-org-retain-visual-state-on-shift t
          ;; In tables, `o' / `O' insert a row instead of moving below /
          ;; above the heading (vim-style).
          evil-org-special-o/O '(table-row)
          ;; Provide additional insert-state bindings tailored for org.
          evil-org-use-additional-insert t)
    :config
    (add-hook 'evil-org-mode-hook #'evil-normalize-keymaps)
    ;; Standard evil-org key theme: navigation + textobjects + additional
    ;; bindings for headings, lists, todos, etc.
    (evil-org-set-key-theme '(navigation insert textobjects additional))
    (evil-define-key 'normal org-mode-map
      (kbd "RET") #'scratch-org/dwim-at-point)
    (evil-define-key 'insert org-mode-map
      (kbd "RET")        #'scratch-org/return
      (kbd "S-<return>") #'scratch-org/shift-return))

  ;; `evil-org-agenda' ships in the `evil-org' package; require +
  ;; activate it once `org-agenda' is up. The setter writes bindings
  ;; directly into `org-agenda-mode-map' (no dedicated minor-mode map).
  ;; After it runs, free `SPC' so the leader still wins there.
  (with-eval-after-load 'org-agenda
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys)
    (evil-define-key 'motion org-agenda-mode-map
      (kbd "SPC") nil)))

;;;; SPC n -- notes
;;
;; Doom-style global "notes" prefix. Available in any buffer (not just
;; org-mode), so you can jump to a note from anywhere. Skips Doom helper
;; commands (`+default/...', `+org/toggle-last-clock', `+org/export-to-clipboard*');
;; everything else maps to stock org commands.

(when (modulep! :editor leader)
  (map! :leader
    ;; Doom-style top-level shortcut: jump straight to org-capture.
    :desc "org capture"             "X" #'org-capture
    (:prefix-map ("n" . "notes")
     :desc "org agenda"             "a" #'org-agenda
     :desc "cancel current clock"   "C" #'org-clock-cancel
     :desc "store link"             "l" #'org-store-link
     :desc "tags view"              "m" #'org-tags-view
     :desc "capture"                "n" #'org-capture
     :desc "goto capture target"    "N" #'org-capture-goto-target
     :desc "goto active clock"      "o" #'org-clock-goto
     :desc "todo list"              "t" #'org-todo-list
     :desc "search view"            "v" #'org-search-view)))

;;;; +roam (org-roam)

(when (modulep! +roam)
  (use-package org-roam
    :defer t
    :commands (org-roam-node-find
               org-roam-node-insert
               org-roam-buffer-toggle
               org-roam-capture
               org-roam-graph)
    :init
    (setq org-roam-v2-ack t
          org-roam-completion-everywhere t
          ;; Prefer faster file-listers (fd / rg) over `find'.
          org-roam-list-files-commands '(fd fdfind rg find))
    :config
    ;; Build the database and start watching `org-roam-directory' the
    ;; first time anything triggers org-roam (`org-roam-node-find',
    ;; `org-roam-capture', etc.). Hooking on `org-roam-mode-hook'
    ;; doesn't work for the common case -- that mode only activates in
    ;; roam-managed buffers (backlinks etc.), not on plain
    ;; `org-roam-node-find', so the DB would never sync.
    (org-roam-db-autosync-enable))

  ;; Global SPC n r submenu: org-roam navigation from any buffer.
  ;; Mirrors Doom's `<leader> n r' bindings.
  (when (modulep! :editor leader)
    (map! :leader
      (:prefix-map ("n" . "notes")
       (:prefix-map ("r" . "roam")
        :desc "open random node"     "a" #'org-roam-node-random
        :desc "find node"            "f" #'org-roam-node-find
        :desc "find ref"             "F" #'org-roam-ref-find
        :desc "graph"                "g" #'org-roam-graph
        :desc "insert node"          "i" #'org-roam-node-insert
        :desc "capture to node"      "n" #'org-roam-capture
        :desc "buffer toggle"        "r" #'org-roam-buffer-toggle
        :desc "buffer dedicated"     "R" #'org-roam-buffer-display-dedicated
        :desc "sync database"        "s" #'org-roam-db-sync
        (:prefix-map ("d" . "by date")
         :desc "prev note"           "b" #'org-roam-dailies-goto-previous-note
         :desc "goto date"           "d" #'org-roam-dailies-goto-date
         :desc "capture date"        "D" #'org-roam-dailies-capture-date
         :desc "next note"           "f" #'org-roam-dailies-goto-next-note
         :desc "goto tomorrow"       "m" #'org-roam-dailies-goto-tomorrow
         :desc "capture tomorrow"    "M" #'org-roam-dailies-capture-tomorrow
         :desc "capture today"       "n" #'org-roam-dailies-capture-today
         :desc "goto today"          "t" #'org-roam-dailies-goto-today
         :desc "capture today"       "T" #'org-roam-dailies-capture-today
         :desc "goto yesterday"      "y" #'org-roam-dailies-goto-yesterday
         :desc "capture yesterday"   "Y" #'org-roam-dailies-capture-yesterday
         :desc "find directory"      "-" #'org-roam-dailies-find-directory)))))

  ;; Localleader (`,m') org-roam bindings, in `org-mode-map' only.
  ;; Outside `use-package' so they install once org loads (i.e. as
  ;; soon as the user opens an org buffer), not deferred until org-roam
  ;; itself is required.
  (when (modulep! :editor leader)
    (with-eval-after-load 'org
      (map! :map org-mode-map :localleader
        (:prefix-map ("m" . "org-roam")
         :desc "demote buffer"      "D" #'org-roam-demote-entire-buffer
         :desc "find node"          "f" #'org-roam-node-find
         :desc "find ref"           "F" #'org-roam-ref-find
         :desc "graph"              "g" #'org-roam-graph
         :desc "insert node"        "i" #'org-roam-node-insert
         :desc "create / get id"    "I" #'org-id-get-create
         :desc "buffer toggle"      "m" #'org-roam-buffer-toggle
         :desc "buffer dedicated"   "M" #'org-roam-buffer-display-dedicated
         :desc "capture"            "n" #'org-roam-capture
         :desc "refile"             "r" #'org-roam-refile
         :desc "replace links"      "R" #'org-roam-link-replace-all
         (:prefix-map ("d" . "by date")
          :desc "prev note"         "b" #'org-roam-dailies-goto-previous-note
          :desc "goto date"         "d" #'org-roam-dailies-goto-date
          :desc "capture date"      "D" #'org-roam-dailies-capture-date
          :desc "next note"         "f" #'org-roam-dailies-goto-next-note
          :desc "goto tomorrow"     "m" #'org-roam-dailies-goto-tomorrow
          :desc "capture tomorrow"  "M" #'org-roam-dailies-capture-tomorrow
          :desc "capture today"     "n" #'org-roam-dailies-capture-today
          :desc "goto today"        "t" #'org-roam-dailies-goto-today
          :desc "capture today"     "T" #'org-roam-dailies-capture-today
          :desc "goto yesterday"    "y" #'org-roam-dailies-goto-yesterday
          :desc "capture yesterday" "Y" #'org-roam-dailies-capture-yesterday
          :desc "find directory"    "-" #'org-roam-dailies-find-directory)
         (:prefix-map ("o" . "node properties")
          :desc "alias add"         "a" #'org-roam-alias-add
          :desc "alias remove"      "A" #'org-roam-alias-remove
          :desc "tag add"           "t" #'org-roam-tag-add
          :desc "tag remove"        "T" #'org-roam-tag-remove
          :desc "ref add"           "r" #'org-roam-ref-add
          :desc "ref remove"        "R" #'org-roam-ref-remove))))))
