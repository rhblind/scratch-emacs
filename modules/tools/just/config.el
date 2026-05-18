;;; modules/tools/just/config.el -*- lexical-binding: t; -*-

(add-to-list 'scratch-treesit-want 'just)

(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(just "https://github.com/casey/tree-sitter-just")))

(with-eval-after-load 'treesit-auto
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'just
                :ts-mode 'just-ts-mode
                :remap 'just-mode
                :url "https://github.com/casey/tree-sitter-just")))

(use-package just-mode
  :defer t)

;; Strip just-ts-mode's own auto-mode-alist entry so treesit-auto
;; controls the just-mode -> just-ts-mode remap (and install prompt).
(setq auto-mode-alist
      (cl-remove-if (lambda (entry) (eq (cdr entry) 'just-ts-mode))
                    auto-mode-alist))

(use-package just-ts-mode
  :defer t)

(use-package justl
  :defer t)

(when (modulep! :tools lsp)
  (add-to-list 'scratch-lsp-auto-modes 'just-ts-mode))

(when (modulep! :editor leader)
  (defmacro scratch-just--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       :desc "list recipes"       "l" #'justl
       :desc "run recipe"         "r" #'justl-exec-recipe-in-dir
       :desc "run default recipe" "d" #'justl-exec-default-recipe))

  (with-eval-after-load 'just-ts-mode
    (scratch-just--def-localleader just-ts-mode-map)))
