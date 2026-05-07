;;; modules/editor/tree-sitter/config.el -*- lexical-binding: t; -*-
;;
;; treesit-auto: detect installed tree-sitter grammars and remap the
;; matching legacy major modes to their `<lang>-ts-mode' equivalents.
;; On Emacs 29+ this gets you better syntax highlighting, indentation,
;; and structural editing across most languages with no per-language
;; config needed.

(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :demand t
  :custom
  ;; Prompt before installing a grammar (instead of installing silently
  ;; on every new language file). Set to t to install on demand without
  ;; asking, or nil to never auto-install.
  (treesit-auto-install 'prompt)
  :config
  (defun scratch-treesit--resolve-langs ()
    "Compute `treesit-auto-langs' = (installed grammars) ∪ `scratch-treesit-want'.
The eager pre-compute is a MAJOR file-open speedup -- without it,
treesit-auto's per-buffer remap-build probes every recipe via
`treesit-language-available-p' (a `dlopen' check), and that adds
up across many recipes. Unioning with `scratch-treesit-want'
(populated by enabled `:lang' modules) keeps `treesit-auto-install-
all' aware of the languages the user wants, not just whatever is
already built locally."
    (setq treesit-auto-langs
          (delete-dups
           (append
            (cl-loop for recipe in treesit-auto-recipe-list
                     when (treesit-language-available-p
                           (treesit-auto-recipe-lang recipe))
                     collect (treesit-auto-recipe-lang recipe))
            scratch-treesit-want))))

  (defun scratch-treesit--strip-unready-from-auto-mode-alist ()
    "Drop `auto-mode-alist' entries pointing at `*-ts-mode' for unready grammars,
BUT ONLY when another entry already handles the same regex pattern
(i.e. there's a fallback mode). Without that guard we'd orphan
languages that have no legacy mode (e.g. `elixir-ts-mode' has no
upstream `elixir-mode' in built-in Emacs; stripping `.ex' / `.exs'
/ `.heex' would route them to fundamental-mode silently).

When a fallback exists (the dual-mode case, e.g. `csharp-mode' for
`.cs'), the strip routes the file there pre-install, where treesit
-auto's prompt path can fire cleanly without a `dlopen' warning.

When no fallback exists, the file goes to `*-ts-mode' as upstream
intends; the user gets a single warning followed by treesit-auto's
install prompt, then a `revert-buffer' once the grammar lands."
    (let ((same-pattern-p
           (lambda (pat)
             (cl-some
              (lambda (other)
                (and (not (eq (cdr other) (cdr (assoc pat auto-mode-alist))))
                     (equal (car other) pat)
                     (symbolp (cdr other))
                     ;; Don't count another *-ts-mode entry for the same
                     ;; lang as a "fallback" -- it'd just route somewhere
                     ;; equally broken.
                     (not (cl-find (cdr other) treesit-auto-recipe-list
                                   :key #'treesit-auto-recipe-ts-mode))))
              auto-mode-alist))))
      (setq auto-mode-alist
            (cl-remove-if
             (lambda (entry)
               (let* ((pat (car entry))
                      (mode (cdr entry))
                      (recipe (and (symbolp mode)
                                   (cl-find mode treesit-auto-recipe-list
                                            :key #'treesit-auto-recipe-ts-mode))))
                 (and recipe
                      (memq (treesit-auto-recipe-lang recipe)
                            treesit-auto-langs)
                      (not (treesit-language-available-p
                            (treesit-auto-recipe-lang recipe)))
                      (funcall same-pattern-p pat))))
             auto-mode-alist))))

  (defun scratch-treesit--refresh-after-install (lang &rest _)
    "After grammar install, refresh `auto-mode-alist' and global remaps.
Otherwise the running session keeps routing files to the legacy
mode and the user has to restart Emacs to pick up the freshly
installed `*-ts-mode'."
    (when (treesit-language-available-p lang)
      (treesit-auto-add-to-auto-mode-alist 'all)
      (when-let* ((recipe (cl-find lang treesit-auto-recipe-list
                                   :key #'treesit-auto-recipe-lang))
                  (ts-mode (treesit-auto-recipe-ts-mode recipe)))
        (dolist (legacy (ensure-list (treesit-auto-recipe-remap recipe)))
          (add-to-list 'major-mode-remap-alist (cons legacy ts-mode))))))

  (advice-add 'treesit-install-language-grammar :after
              #'scratch-treesit--refresh-after-install)

  ;; Resolve eagerly first so `treesit-auto-add-to-auto-mode-alist'
  ;; below has a sensible base. Re-resolve on `emacs-startup-hook'
  ;; because `:lang' modules load AFTER `:editor tree-sitter' in the
  ;; usual `scratch!' declaration order, so their pushes to
  ;; `scratch-treesit-want' arrive too late for the first pass.
  (scratch-treesit--resolve-langs)
  (treesit-auto-add-to-auto-mode-alist 'all)
  (scratch-treesit--strip-unready-from-auto-mode-alist)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (scratch-treesit--resolve-langs)
              (treesit-auto-add-to-auto-mode-alist 'all)
              (scratch-treesit--strip-unready-from-auto-mode-alist)))
  (global-treesit-auto-mode))
