;;; lisp/scratch-code.el --- prog-mode helpers -*- lexical-binding: t; -*-
;;
;; Tiny dispatchers for the framework's `SPC c' (code) leader prefix.
;; Each function picks the best implementation available given the
;; modules currently active -- so a single `c f' / `c x' / etc. binding
;; works whether or not LSP / flycheck is attached.

(defun scratch/format-region-or-buffer ()
  "Format the active region (or whole buffer) using the best handler.
Prefers `lsp-format-region' / `lsp-format-buffer' when an LSP server
attached to the buffer can handle formatting; falls back to the
mode's `indent-region-function' (typically the major-mode's indent
rules)."
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end)       (point-max))))
    (cond
     ((and (bound-and-true-p lsp-mode)
           (fboundp 'lsp-feature?)
           (or (lsp-feature? "textDocument/rangeFormatting")
               (lsp-feature? "textDocument/formatting")))
      (if (use-region-p)
          (lsp-format-region beg end)
        (lsp-format-buffer)))
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

(provide 'scratch-code)
;;; scratch-code.el ends here
