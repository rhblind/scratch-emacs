;;; lisp/scratch-code.el --- prog-mode helpers -*- lexical-binding: t; -*-
;;
;; Tiny dispatchers for the framework's `SPC c' (code) leader prefix.
;; Each function picks the best implementation available given the
;; modules currently active -- so a single `c f' / `c x' / etc. binding
;; works whether or not LSP / flycheck is attached.

(defun scratch/format ()
  "Format the active region (or whole buffer) using the best handler.

Dispatch is capability-aware: it asks the attached LSP server
(via `lsp-feature?') exactly what it supports, picks the right
formatter, and gracefully degrades when a request can't be served.

Region selected:
  1. LSP `textDocument/rangeFormatting' -- format just the region.
  2. LSP `textDocument/formatting' -- whole-buffer (apheleia can't do
     regions either, so this is the next-best thing).
  3. `apheleia-format-buffer' -- whole-buffer via the mode's CLI
     formatter (prettier / gofmt / mix format / ...).
  4. `indent-region' on the region.

No region:
  1. LSP `textDocument/formatting'.
  2. `apheleia-format-buffer'.
  3. `indent-region' on the whole buffer.

Bound to `SPC c f' under `:editor leader' and discoverable via
`M-x format'."
  (interactive)
  (let* ((region-active (use-region-p))
         (beg (if region-active (region-beginning) (point-min)))
         (end (if region-active (region-end)       (point-max)))
         (lsp-on (and (bound-and-true-p lsp-mode)
                      (fboundp 'lsp-feature?)))
         (lsp-can-format (and lsp-on (lsp-feature? "textDocument/formatting")))
         (lsp-can-range  (and lsp-on (lsp-feature? "textDocument/rangeFormatting")))
         (apheleia-can-format
          (and (bound-and-true-p apheleia-mode)
               (fboundp 'apheleia-format-buffer)
               (apheleia--get-formatters))))
    (cond
     ((and region-active lsp-can-range)
      (lsp-format-region beg end))
     ((and region-active lsp-can-format)
      (message "LSP server doesn't support range formatting; formatting buffer.")
      (lsp-format-buffer))
     ((and (not region-active) lsp-can-format)
      (lsp-format-buffer))
     (apheleia-can-format
      (when region-active
        (message "apheleia doesn't support range formatting; formatting buffer."))
      (apheleia-format-buffer (apheleia--get-formatters)))
     (t
      (indent-region beg end)))))

(defun scratch/find-implementations ()
  "Find implementations of the symbol at point.
Uses `lsp-find-implementation' when LSP is attached and the server
supports it; falls back to `xref-find-definitions' (which is a useful
approximation for elisp / etags / dumb-jump backends)."
  (interactive)
  (cond
   ((and (bound-and-true-p lsp-mode)
         (fboundp 'lsp-feature?)
         (lsp-feature? "textDocument/implementation"))
    (call-interactively #'lsp-find-implementation))
   (t (call-interactively #'xref-find-definitions))))

(defun scratch/describe-symbol-or-lsp ()
  "Show docs for the symbol at point using the best handler.
Uses `lsp-describe-thing-at-point' (server-side hover info) when
LSP is attached; falls back to `describe-symbol' for elisp / built-in
symbols."
  (interactive)
  (cond
   ((and (bound-and-true-p lsp-mode)
         (fboundp 'lsp-feature?)
         (lsp-feature? "textDocument/hover"))
    (lsp-describe-thing-at-point))
   (t (call-interactively #'describe-symbol))))

(defun scratch/delete-trailing-newlines ()
  "Delete any blank lines at the end of the buffer."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (skip-chars-backward " \t\n\r")
    (when (looking-at-p "[ \t\n\r]+\\'")
      (delete-region (point) (point-max)))))

;;;; Region sort -- sort words or symbols alphabetically inside a
;;;; visual selection. Thin wrappers around `sort-regexp-fields'.

(defun scratch/sort-words (reverse beg end)
  "Sort words in region alphabetically; prefix arg for REVERSE.
Respects `sort-fold-case'."
  (interactive "*P\nr")
  (sort-regexp-fields reverse "\\w+" "\\&" beg end))

(defun scratch/sort-symbols (reverse beg end)
  "Sort symbols in region alphabetically; prefix arg for REVERSE.
Respects `sort-fold-case'."
  (interactive "*P\nr")
  (sort-regexp-fields reverse "\\(\\sw\\|\\s_\\)+" "\\&" beg end))

(defun scratch/rename ()
  "Rename the symbol at point in the current buffer.
Uses `symbol-overlay-rename' when `symbol-overlay-mode' is active;
falls back to `query-replace'."
  (interactive)
  (cond
   ((and (bound-and-true-p symbol-overlay-mode)
         (fboundp 'symbol-overlay-rename))
    (call-interactively #'symbol-overlay-rename))
   (t (call-interactively #'query-replace))))

(defalias 'sort-words   #'scratch/sort-words)
(defalias 'sort-symbols #'scratch/sort-symbols)

;;;; Delete carriage returns -- strip ^M (CR) characters from the
;;;; buffer. Useful for C# templates and other Windows-origin files.

(defun scratch/delete-carriage-returns ()
  "Delete all carriage-return (^M) characters in the current buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0))
      (while (search-forward "\r" nil t)
        (replace-match "")
        (cl-incf count))
      (message "Removed %d carriage return%s" count (if (= count 1) "" "s")))))

(provide 'scratch-code)
;;; scratch-code.el ends here
