;;; modules/editor/smartparens/config.el -*- lexical-binding: t; -*-
;;
;; smartparens: structured editing for paired delimiters (parens,
;; brackets, quotes, tags, etc.). `smartparens-global-mode' kicks in
;; on first user input so we don't pay startup cost for batch sessions
;; or scratch buffers.

(use-package smartparens
  :hook (find-file . smartparens-global-mode)
  :hook (minibuffer-setup . scratch-smartparens--maybe-enable-h)
  :commands (sp-pair sp-local-pair sp-with-modes
             sp-point-in-comment sp-point-in-string)
  :init
  (defun scratch-smartparens--maybe-enable-h ()
    "Activate `smartparens-mode' in the eval-expression minibuffer.
Other minibuffer prompts stay smartparens-free (auto-pairing in a
search prompt or custom-set-* dialog is more annoying than helpful)."
    (when (and smartparens-global-mode
               (memq this-command '(eval-expression evil-ex)))
      (smartparens-mode 1)))
  :config
  ;; Sensible per-language pair definitions (HTML tags, comment
  ;; closers, lisp `( ... )' etc.).
  (require 'smartparens-config)

  ;; Don't auto-pair `'' in minibuffer prompts -- it fights ex-style
  ;; search and `read-string'. (`\\' isn't a default sp pair, so no
  ;; need to suppress it.)
  (sp-local-pair '(minibuffer-mode minibuffer-inactive-mode)
                 "'" nil :actions nil)

  ;; Show the matching pair from inside (smartparens highlights the
  ;; outer delimiter pair when point is between them).
  (setq sp-show-pair-from-inside t
        ;; Don't echo "Wrap with ..." after every pair insert.
        sp-message-width nil))
