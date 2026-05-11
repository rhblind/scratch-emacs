;;; modules/tools/editorconfig/config.el -*- lexical-binding: t; -*-
;;
;; Built-in EditorConfig support (Emacs 30+). Reads `.editorconfig'
;; files and applies per-file indentation, charset, line-ending, and
;; whitespace settings. Projects that ship an `.editorconfig' get
;; their style respected automatically, no per-mode config needed.
;;
;; The built-in implementation is pure Elisp (no external binary) and
;; caches parsed results, so the overhead per buffer is negligible.

(require 'editorconfig)

(editorconfig-mode 1)

;; When ws-butler is active, let editorconfig delegate trimming to it
;; so only touched lines are cleaned (avoids noisy diffs).
(when (modulep! :editor ws-butler)
  (setq editorconfig-trim-whitespaces-mode 'ws-butler-mode))

;; Archives (zip, docx, xlsx, pptx) are zipped XML; applying
;; editorconfig settings to them can interfere with opening.
(add-to-list 'editorconfig-exclude-regexps
             "\\.\\(zip\\|\\(doc\\|xls\\|ppt\\)x\\)\\'")

;; Org-mode requires tab-width = 8; prevent editorconfig from
;; overriding it via indent_size.
(add-hook 'editorconfig-after-apply-functions
          (defun scratch-editorconfig-protect-org-tab-width (props)
            (when (and (gethash 'indent_size props)
                       (derived-mode-p 'org-mode))
              (setq tab-width 8))))
