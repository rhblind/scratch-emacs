;;; modules/lang/markdown/config.el -*- lexical-binding: t; -*-
;;
;; Sensible defaults for [[https://jblevins.org/projects/markdown-mode/][markdown-mode]]: visual line wrapping, code-block
;; syntax highlighting, scaled heading faces. `:ui fonts' already
;; auto-enables `mixed-pitch-mode' in `markdown-mode' / `gfm-mode' so
;; body text gets the variable-pitch treatment.

(use-package markdown-mode
  :mode (("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode))
  :hook (markdown-mode . visual-line-mode)
  :init
  ;; Highlight code blocks per their declared language (` ```python`,
  ;; etc.) instead of leaving them as plain text.
  (setq markdown-fontify-code-blocks-natively t
        ;; `:` for tables; bare URLs become clickable links.
        markdown-enable-math nil
        markdown-italic-underscore t
        markdown-asymmetric-header t
        markdown-command '("cmark-gfm" "-e" "table" "-e" "strikethrough"
                          "-e" "autolink" "--unsafe")))

;; Heading face polish ported from the user's Doom config: scaled
;; h1..h6 with weight tapering off at deeper levels.
(with-eval-after-load 'markdown-mode
  (which-key-add-key-based-replacements
    "C-c C-a" "links"
    "C-c C-c" "commands"
    "C-c C-s" "style"
    "C-c C-t" "headers"
    "C-c C-x" "extras")
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

;;;; Live preview via xwidget-webkit

(defcustom scratch-markdown-preview-display-alist
  '((side . right)
    (window-width . 0.5))
  "Display alist passed to `display-buffer-in-side-window' for the preview.
Common keys: `side' (right, left, bottom, top), `window-width' (fraction
or columns), `slot' (integer for ordering multiple side windows)."
  :type '(alist :key-type symbol :value-type sexp)
  :group 'markdown)

(add-hook 'xwidget-webkit-mode-hook
          (lambda () (goto-address-mode -1)))

(defvar scratch-markdown--post-render-js
  "document.querySelectorAll('a[href]').forEach(function(a){
     a.setAttribute('data-href',a.getAttribute('href'));
     a.removeAttribute('href');
     a.style.cursor='pointer';});
   document.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(function(h){
     if(!h.id){
       h.id=h.textContent.trim().toLowerCase()
         .replace(/[^\\w\\s-]/g,'').replace(/\\s+/g,'-');
     }});"
  "Post-render JS: disarm links and add GFM-style heading IDs.")

(defun scratch-markdown--post-render (xw)
  "Run post-render fixups on xwidget XW."
  (xwidget-webkit-execute-script xw scratch-markdown--post-render-js))

(defun scratch-markdown--handle-link (result xw)
  "Open the link described by JSON RESULT, using xwidget XW for anchors."
  (let* ((data (json-parse-string result :object-type 'alist))
         (href (alist-get 'href data))
         (src  (alist-get 'src data)))
    (cond
     ((and href (not (string-empty-p href)) (string-prefix-p "#" href) xw)
      (xwidget-webkit-execute-script xw
        (format "var t=document.getElementById(%s);if(t)t.scrollIntoView({behavior:'smooth'});"
                (json-encode (substring href 1))))
      (when-let* ((win (get-buffer-window (xwidget-buffer xw))))
        (select-window win)
        (evil-normal-state)))
     ((and href (not (string-empty-p href)) (string-match-p "\\`https?://" href))
      (browse-url href))
     ((and src (not (string-empty-p src)) (string-match-p "\\`https?://" src))
      (browse-url src)))))

(defun scratch-markdown--preview-buffer-p (buf)
  "Return non-nil if BUF is a markdown preview xwidget buffer."
  (seq-some (lambda (b)
              (eq (buffer-local-value 'scratch-markdown--preview-buffer b) buf))
            (buffer-list)))

(defun scratch-markdown--follow-link-at-click (event)
  "Handle mouse clicks in the markdown preview xwidget.
Anchor links scroll within the preview.  External URLs open in a
browser.  Clicks on non-link areas are ignored.  Falls through to
default behavior in non-preview xwidget buffers."
  (interactive "e")
  (let* ((posn (event-start event))
         (win (posn-window posn))
         (buf (window-buffer win)))
    (if (not (scratch-markdown--preview-buffer-p buf))
        (mouse-set-point event)
      (let* ((xy (posn-x-y posn))
             (x (car xy))
             (y (cdr xy))
             (xw (save-current-buffer
                   (set-buffer buf)
                   (xwidget-at (point-min)))))
        (if xw
            (progn
              (select-window win)
              (xwidget-webkit-execute-script xw
                (format
                 "var el=document.elementFromPoint(%d,%d);
                  var a=el&&el.closest('a');
                  var img=el&&el.closest('img');
                  JSON.stringify({href:a&&a.getAttribute('data-href')||'',src:img&&img.src||''});"
                 x y)
                `(lambda (result)
                   (run-at-time 0.01 nil #'scratch-markdown--handle-link result ,xw))))
          (mouse-set-point event))))))

(with-eval-after-load 'xwidget
  (define-key xwidget-webkit-mode-map [mouse-1]
    #'scratch-markdown--follow-link-at-click))

(defvar-local scratch-markdown--preview-buffer nil
  "The xwidget-webkit buffer showing this markdown buffer's preview.")

(defvar-local scratch-markdown--preview-tempfile nil
  "Temp HTML file backing the initial xwidget load.")

(defun scratch-markdown--preview-css ()
  "Generate a preview stylesheet from the current Emacs theme."
  (let* ((bg      (face-background 'default))
         (fg      (face-foreground 'default))
         (link    (or (face-foreground 'link nil t) "#0969da"))
         (border  (or (face-background 'region nil t) "#d1d9e0"))
         (comment (or (face-foreground 'font-lock-comment-face nil t) fg))
         (code-bg (or (face-background 'markdown-code-face nil t)
                      (face-background 'shadow nil t)
                      border))
         (h-fg    (or (face-foreground 'markdown-header-face nil t) fg)))
    (format "<style>
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
       max-width: 48em; margin: 2em auto; padding: 0 1em; line-height: 1.6;
       background: %s; color: %s; }
h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; color: %s; }
h1 { border-bottom: 1px solid %s; padding-bottom: 0.3em; }
h2 { border-bottom: 1px solid %s; padding-bottom: 0.3em; }
pre { background: %s; padding: 1em; border-radius: 6px; overflow-x: auto; }
code { background: %s; padding: 0.2em 0.4em; border-radius: 3px; font-size: 0.9em; }
pre code { background: none; padding: 0; }
blockquote { border-left: 3px solid %s; margin-left: 0; padding-left: 1em; color: %s; }
table { border-collapse: collapse; }
th, td { border: 1px solid %s; padding: 0.4em 0.8em; }
th { background: %s; }
img { max-width: 100%%; }
a { color: %s; }
a[data-href] { color: %s; text-decoration: underline; cursor: pointer; }
</style>"
            bg fg h-fg border border code-bg code-bg
            border comment border code-bg link link)))

(defun scratch-markdown--render-body ()
  "Return the HTML body for the current markdown buffer via `markdown-command'."
  (let ((cmd (if (listp markdown-command) markdown-command
               (list markdown-command))))
    (with-output-to-string
      (apply #'call-process-region (point-min) (point-max)
             (car cmd) nil standard-output nil (cdr cmd)))))

(defun scratch-markdown--render-html ()
  "Return a standalone HTML string for the current markdown buffer."
  (let ((base-dir (or (and buffer-file-name
                           (file-name-directory buffer-file-name))
                      default-directory)))
    (concat "<!DOCTYPE html><html><head><meta charset=\"utf-8\">"
            "<base href=\"" (browse-url-file-url (expand-file-name base-dir)) "/\">"
            (scratch-markdown--preview-css)
            "</head><body>" (scratch-markdown--render-body)
            "<script>" scratch-markdown--post-render-js "</script>"
            "</body></html>")))

(defun scratch-markdown--refresh-preview ()
  "Re-render the markdown preview, preserving scroll position."
  (when-let* ((xw-buf scratch-markdown--preview-buffer)
              ((buffer-live-p xw-buf)))
    (let* ((src-buf (current-buffer))
           (xw (progn (set-buffer xw-buf)
                      (prog1 (xwidget-at (point-min))
                        (set-buffer src-buf)))))
      (when xw
        (let ((body (scratch-markdown--render-body))
              (css (scratch-markdown--preview-css)))
          (xwidget-webkit-execute-script xw
            (format "document.body.innerHTML = %s; document.querySelector('style').outerHTML = %s; %s"
                    (json-encode body)
                    (json-encode css)
                    scratch-markdown--post-render-js)))))))

(defun scratch-markdown--on-theme-change (&rest _)
  "Re-render the preview CSS when the Emacs theme changes."
  (dolist (buf (buffer-list))
    (when (buffer-local-value 'scratch-markdown--preview-buffer buf)
      (save-current-buffer
        (set-buffer buf)
        (scratch-markdown--refresh-preview)))))

(add-hook 'enable-theme-functions #'scratch-markdown--on-theme-change)

(defun scratch/markdown-preview ()
  "Toggle a live markdown preview.
In GUI Emacs, opens an xwidget-webkit side window that re-renders on
every save with scroll position preserved. In terminal Emacs, falls
back to `markdown-preview' (opens in external browser)."
  (interactive)
  (unless (derived-mode-p 'markdown-mode 'gfm-mode)
    (user-error "Not a markdown buffer"))
  (let ((cmd (if (listp markdown-command) (car markdown-command) markdown-command)))
    (unless (executable-find cmd)
      (user-error "Markdown preview requires `%s'; install it with your package manager" cmd)))
  (if (not (display-graphic-p))
      (call-interactively #'markdown-preview)
    (cond
     ((and scratch-markdown--preview-buffer
           (buffer-live-p scratch-markdown--preview-buffer)
           (get-buffer-window scratch-markdown--preview-buffer))
      (remove-hook 'after-save-hook #'scratch-markdown--refresh-preview t)
      (remove-hook 'after-revert-hook #'scratch-markdown--refresh-preview t)
      (let ((kill-buffer-query-functions nil))
        (kill-buffer scratch-markdown--preview-buffer))
      (when scratch-markdown--preview-tempfile
        (ignore-errors (delete-file scratch-markdown--preview-tempfile))
        (setq scratch-markdown--preview-tempfile nil))
      (setq scratch-markdown--preview-buffer nil)
      (message "Markdown preview closed."))
     (t
      (when (and scratch-markdown--preview-buffer
                 (buffer-live-p scratch-markdown--preview-buffer))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer scratch-markdown--preview-buffer)))
      (let* ((src-buf (current-buffer))
             (html (scratch-markdown--render-html))
             (tmp (make-temp-file "md-preview-" nil ".html" html))
             (url (concat "file://" tmp))
             xw-buf)
        (save-window-excursion
          (xwidget-webkit-browse-url url t)
          (setq xw-buf (current-buffer)))
        (set-buffer src-buf)
        (setq scratch-markdown--preview-tempfile tmp
              scratch-markdown--preview-buffer xw-buf)
        (add-hook 'after-save-hook #'scratch-markdown--refresh-preview nil t)
        (add-hook 'after-revert-hook #'scratch-markdown--refresh-preview nil t)
        (display-buffer-in-side-window xw-buf
                                       scratch-markdown-preview-display-alist)
        (select-window (get-buffer-window xw-buf)))))))

;;;; Preview / source outline sync

(defun scratch-markdown--preview-xwidget ()
  "Return the xwidget for the current markdown preview, or nil."
  (when-let* ((xw-buf scratch-markdown--preview-buffer)
              ((buffer-live-p xw-buf)))
    (let ((cur (current-buffer)))
      (set-buffer xw-buf)
      (prog1 (xwidget-at (point-min))
        (set-buffer cur)))))

(defun scratch-markdown--scroll-preview-to-heading ()
  "After `consult-outline', scroll the preview to the matching heading."
  (when-let* ((xw (scratch-markdown--preview-xwidget)))
    (let ((heading (save-excursion
                     (end-of-line)
                     (when (re-search-backward "^\\(#+\\) +\\(.*\\)" nil t)
                       (string-trim (match-string-no-properties 2))))))
      (when heading
        (xwidget-webkit-execute-script xw
          (format "var h = Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6')).find(function(el){return el.textContent.trim() === %s}); if(h) h.scrollIntoView({behavior:'smooth'});"
                  (json-encode heading)))))))

(defun scratch-markdown--xwidget-heading-picker (json-str xw)
  "Show a heading picker from JSON-STR and scroll xwidget XW to selection."
  (let* ((headings (json-parse-string json-str :object-type 'alist))
         (candidates
          (mapcar (lambda (h)
                    (let* ((level (string-to-number (substring (alist-get 'level h) 1)))
                           (indent (make-string (* 2 (1- level)) ?\s))
                           (text (alist-get 'text h))
                           (idx (alist-get 'index h)))
                      (cons (concat indent text) idx)))
                  (append headings nil)))
         (chosen (completing-read "Heading: " candidates nil t))
         (idx (cdr (assoc chosen candidates))))
    (when idx
      (xwidget-webkit-execute-script xw
        (format "document.querySelectorAll('h1,h2,h3,h4,h5,h6')[%d].scrollIntoView({behavior:'smooth'});"
                idx)))))

(defun scratch/markdown-outline ()
  "In a markdown buffer, run `consult-outline' then sync the preview.
In an xwidget preview buffer, show a heading picker from the HTML."
  (interactive)
  (cond
   ((derived-mode-p 'markdown-mode 'gfm-mode)
    (consult-outline)
    (scratch-markdown--scroll-preview-to-heading))
   ((derived-mode-p 'xwidget-webkit-mode)
    (let ((xw (xwidget-at (point-min))))
      (unless xw (user-error "No xwidget in this buffer"))
      (xwidget-webkit-execute-script xw
        "JSON.stringify(Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6')).map(function(el,i){return {index:i,level:el.tagName,text:el.textContent}}))"
        `(lambda (result)
           (run-at-time 0.01 nil
             `(lambda ()
                (scratch-markdown--xwidget-heading-picker ,result ,,xw)))))))
   (t (consult-outline))))

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
      :desc "preview"                "p" #'scratch/markdown-preview
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

    ;; Override SPC s o in markdown and xwidget preview buffers.
    ;; Uses general's :predicate on the override map so it takes
    ;; precedence over the global leader binding.
    (general-define-key
     :keymaps 'override
     :states '(normal visual motion)
     :prefix scratch-leader-key
     :predicate '(derived-mode-p 'markdown-mode)
     "s o" #'scratch/markdown-outline)
    (general-define-key
     :keymaps 'override
     :states '(normal visual motion)
     :prefix scratch-leader-key
     :predicate '(derived-mode-p 'xwidget-webkit-mode)
     "s o" #'scratch/markdown-outline)))
