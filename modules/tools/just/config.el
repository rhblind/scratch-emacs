;;; modules/tools/just/config.el -*- lexical-binding: t; -*-

(add-to-list 'scratch-treesit-want 'just)

(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(just "https://github.com/casey/tree-sitter-just")))

(use-package just-mode
  :defer t)

(use-package just-ts-mode
  :defer t
  :when (treesit-language-available-p 'just)
  :mode ("\\(?:[Jj]ustfile\\|\\.just\\)\\'" . just-ts-mode))

(when (treesit-language-available-p 'just)
  (add-to-list 'major-mode-remap-alist '(just-mode . just-ts-mode)))

(use-package justl
  :defer t)

(when (modulep! :tools lsp)
  (dolist (mode '(just-ts-mode just-mode))
    (add-to-list 'scratch-lsp-auto-modes mode)))

(when (modulep! :editor leader)
  (defmacro scratch-just--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       :desc "list recipes"       "l" #'justl
       :desc "run recipe"         "r" #'justl-exec-recipe-in-dir
       :desc "run default recipe" "d" #'justl-exec-default-recipe))

  (with-eval-after-load 'just-ts-mode
    (scratch-just--def-localleader just-ts-mode-map))
  (with-eval-after-load 'just-mode
    (scratch-just--def-localleader just-mode-map)))
