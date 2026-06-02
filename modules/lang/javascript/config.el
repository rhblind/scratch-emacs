;;; modules/lang/javascript/config.el -*- lexical-binding: t; -*-
;;
;; JavaScript / TypeScript / TSX support. Built-in tree-sitter modes
;; (Emacs 30+) for all file types. Deno support gated behind `+deno'.
;;
;; LSP: ts-ls for Node projects, deno-ls for Deno projects (when +deno).
;; Formatting: auto-detects prettier vs biome; Deno projects use deno fmt.

;;; Tree-sitter grammars

(dolist (lang '(javascript typescript tsx))
  (add-to-list 'scratch-treesit-want lang))

(with-eval-after-load 'treesit
  (dolist (entry '((javascript "https://github.com/tree-sitter/tree-sitter-javascript")
                   (typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                               "master" "typescript/src")
                   (tsx        "https://github.com/tree-sitter/tree-sitter-typescript"
                               "master" "tsx/src")))
    (add-to-list 'treesit-language-source-alist entry)))

;;; Mode remapping (tree-sitter equivalents)

(when (treesit-language-available-p 'javascript)
  (dolist (legacy '(js-mode javascript-mode))
    (add-to-list 'major-mode-remap-alist (cons legacy 'js-ts-mode))))

(when (treesit-language-available-p 'typescript)
  (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode)))

;;; auto-mode-alist for extensions not covered by built-in defaults

(dolist (entry '(("\\.mjs\\'" . js-ts-mode)
                 ("\\.cjs\\'" . js-ts-mode)
                 ("\\.mts\\'" . typescript-ts-mode)
                 ("\\.cts\\'" . typescript-ts-mode)
                 ("\\.tsx\\'" . tsx-ts-mode)
                 ("\\.jsx\\'" . tsx-ts-mode)))
  (add-to-list 'auto-mode-alist entry))

;;; Project detection (worktree-safe)

(defun scratch-javascript--project-root ()
  "Return the project root, or nil.
Uses `project-root' which resolves via `git rev-parse --show-toplevel',
returning the worktree root (not the main repo root) in git worktrees."
  (when-let* ((proj (project-current))
              (root (project-root proj)))
    root))

(defun scratch-javascript--deno-project-p ()
  "Return non-nil if deno.json or deno.jsonc exists at or above the current file.
Walks up from `default-directory', bounded by `project-root' so it
doesn't escape a git worktree. Handles monorepos where deno.json
lives in a subdirectory (e.g. apps/frontend/deno.json)."
  (when-let* ((proj (project-current))
              (boundary (expand-file-name (project-root proj))))
    (locate-dominating-file
     default-directory
     (lambda (dir)
       (and (string-prefix-p boundary (expand-file-name dir))
            (or (file-exists-p (expand-file-name "deno.json" dir))
                (file-exists-p (expand-file-name "deno.jsonc" dir))))))))

(defun scratch-javascript--node-project-p ()
  "Return non-nil if package.json exists at or above the current file.
Bounded by `project-root' (worktree-safe)."
  (when-let* ((proj (project-current))
              (boundary (expand-file-name (project-root proj))))
    (locate-dominating-file
     default-directory
     (lambda (dir)
       (and (string-prefix-p boundary (expand-file-name dir))
            (file-exists-p (expand-file-name "package.json" dir)))))))

;;; Formatting (auto-detect prettier vs biome)

(defvar scratch-javascript--prettier-config-files
  '(".prettierrc" ".prettierrc.json" ".prettierrc.yml" ".prettierrc.yaml"
    ".prettierrc.js" ".prettierrc.cjs" ".prettierrc.mjs" ".prettierrc.toml"
    "prettier.config.js" "prettier.config.cjs" "prettier.config.mjs")
  "Files that signal a project uses prettier for formatting.")

(defun scratch-javascript--detect-formatter ()
  "Return the apheleia formatter symbol for the current JS/TS project.
Walks up from the file looking for prettier or biome config, bounded
by `project-root'. Defaults to biome when no config is found."
  (if-let* ((proj (project-current))
            (boundary (expand-file-name (project-root proj))))
      (cond
       ((locate-dominating-file
         default-directory
         (lambda (dir)
           (and (string-prefix-p boundary (expand-file-name dir))
                (cl-some (lambda (f) (file-exists-p (expand-file-name f dir)))
                         scratch-javascript--prettier-config-files))))
        (if (derived-mode-p 'typescript-ts-mode 'tsx-ts-mode)
            'prettier-typescript
          'prettier-javascript))
       (t 'biome))
    'biome))

(defun scratch-javascript--set-formatter ()
  "Set the buffer-local apheleia formatter for JS/TS files."
  (when (bound-and-true-p apheleia-mode)
    (setq-local apheleia-formatter (scratch-javascript--detect-formatter))))

(dolist (hook '(js-ts-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook))
  (add-hook hook #'scratch-javascript--set-formatter))

;;; Deno formatters (+deno)

(when (modulep! +deno)
  (with-eval-after-load 'apheleia
    (dolist (entry '((denofmt-ts   "deno" "fmt" "-" "--ext" "ts")
                     (denofmt-tsx  "deno" "fmt" "-" "--ext" "tsx")
                     (denofmt-js   "deno" "fmt" "-" "--ext" "js")
                     (denofmt-json "deno" "fmt" "-" "--ext" "json")
                     (denofmt-md   "deno" "fmt" "-" "--ext" "md")))
      (setf (alist-get (car entry) apheleia-formatters) (cdr entry)))))

;;; LSP

(when (modulep! :tools lsp)
  (with-eval-after-load 'lsp-mode
    (dolist (pat '("[/\\\\]node_modules\\'"
                   "[/\\\\]\\.next\\'"
                   "[/\\\\]dist\\'"
                   "[/\\\\]build\\'"
                   "[/\\\\]\\.turbo\\'"
                   "[/\\\\]\\.deno\\'"))
      (add-to-list 'lsp-file-watch-ignored-directories pat)))

  (if (modulep! +deno)
      (progn
        (defun scratch-javascript--lsp-maybe ()
          "Start LSP for JS/TS only if not in a Deno project.
Deno projects use deno-ls via their own derived-mode hooks."
          (unless (scratch-javascript--deno-project-p)
            (lsp-deferred)))
        (dolist (hook '(js-ts-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook))
          (add-hook hook #'scratch-javascript--lsp-maybe)))
    (dolist (mode '(js-ts-mode typescript-ts-mode tsx-ts-mode))
      (add-to-list 'scratch-lsp-auto-modes mode))))

;;; Deno (+deno flag)

(when (modulep! +deno)
  (define-derived-mode deno-ts-mode typescript-ts-mode "Deno[TS]"
    "Major mode for Deno TypeScript files."
    :group 'scratch-javascript
    (setq-local apheleia-formatter 'denofmt-ts)
    (setq-local lsp-disabled-clients '(ts-ls jsts-ls)))

  (define-derived-mode deno-tsx-mode tsx-ts-mode "Deno[TSX]"
    "Major mode for Deno TSX files."
    :group 'scratch-javascript
    (setq-local apheleia-formatter 'denofmt-tsx)
    (setq-local lsp-disabled-clients '(ts-ls jsts-ls)))

  (define-derived-mode deno-js-mode js-ts-mode "Deno[JS]"
    "Major mode for Deno JavaScript files."
    :group 'scratch-javascript
    (setq-local apheleia-formatter 'denofmt-js)
    (setq-local lsp-disabled-clients '(ts-ls jsts-ls)))

  (define-derived-mode deno-json-mode json-ts-mode "Deno[JSON]"
    "Major mode for Deno JSON files."
    :group 'scratch-javascript
    (setq-local apheleia-formatter 'denofmt-json))

  (with-eval-after-load 'markdown-mode
    (define-derived-mode deno-md-mode markdown-mode "Deno[MD]"
      "Major mode for Deno Markdown files."
      :group 'scratch-javascript
      (setq-local apheleia-formatter 'denofmt-md)))

  (defun scratch-javascript--maybe-activate-deno-mode ()
    "Switch to appropriate Deno mode if in a Deno project."
    (when (scratch-javascript--deno-project-p)
      (pcase major-mode
        ('typescript-ts-mode (deno-ts-mode))
        ('tsx-ts-mode (deno-tsx-mode))
        ('js-ts-mode (deno-js-mode))
        ('json-ts-mode (deno-json-mode))
        ('markdown-mode (when (fboundp 'deno-md-mode) (deno-md-mode))))))

  (add-hook 'after-change-major-mode-hook #'scratch-javascript--maybe-activate-deno-mode)

  (when (modulep! :tools lsp)
    ;; Register language IDs for deno derived modes so deno-ls knows
    ;; what language the buffer is in.
    (with-eval-after-load 'lsp-mode
      (dolist (entry '((deno-ts-mode . "typescript")
                       (deno-tsx-mode . "typescriptreact")
                       (deno-js-mode . "javascript")))
        (add-to-list 'lsp-language-id-configuration entry)))

    ;; Override lsp-mode's built-in deno-ls client (registered in
    ;; lsp-javascript.el). The built-in uses an activation-fn that
    ;; matches ALL JS/TS files; ours restricts to deno-* derived modes.
    ;; Must load after lsp-javascript so our `lsp-register-client'
    ;; overwrites the built-in (same :server-id 'deno-ls).
    (with-eval-after-load 'lsp-javascript
      (lsp-register-client
       (make-lsp-client
        :new-connection (lsp-stdio-connection
                         (lambda () (list (or (executable-find "deno") "deno") "lsp")))
        :activation-fn (lambda (_file-name mode)
                         (memq mode '(deno-ts-mode deno-tsx-mode deno-js-mode)))
        :priority 10
        :server-id 'deno-ls
        :initialization-options (lambda () (list :clientInfo (list :name "deno-ls")))
        :notification-handlers (lsp-ht ("window/logMessage" #'ignore))
        :add-on? nil)))

    (dolist (hook '(deno-ts-mode-hook deno-tsx-mode-hook deno-js-mode-hook))
      (add-hook hook #'lsp-deferred))))

;;; ESLint (via lsp-eslint addon, gated on :checkers syntax)
;; lsp-eslint ships bundled with lsp-mode; just require the feature.

(when (and (modulep! :checkers syntax) (modulep! :tools lsp))
  (with-eval-after-load 'lsp-mode
    (require 'lsp-eslint nil t)))

;;; Testing (jest)

(use-package jest
  :defer t
  :commands (jest jest-file jest-function jest-repeat jest-popup)
  :init
  (dolist (hook '(js-ts-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook))
    (add-hook hook (lambda () (setq-local compilation-buffer-name-function
                                          (lambda (_) "*jest*"))))))

(defun scratch-javascript--jest-project-root-a (&rest _)
  "Override jest's project root with `project-root' (worktree-safe)."
  (scratch-javascript--project-root))

(with-eval-after-load 'jest
  (when (fboundp 'jest--project-root)
    (advice-add 'jest--project-root :override
                #'scratch-javascript--jest-project-root-a))
  (when (fboundp 'jest-test-project-root)
    (advice-add 'jest-test-project-root :override
                #'scratch-javascript--jest-project-root-a)))

;;; Localleader bindings

(when (modulep! :editor leader)
  (defmacro scratch-javascript--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       (:prefix-map ("t" . "test")
        :desc "run all"               "a" #'jest-popup
        :desc "verify file"           "v" #'jest-file
        :desc "verify single"         "s" #'jest-function
        :desc "rerun last"            "r" #'jest-repeat)
       :desc "format buffer"         "=" #'lsp-format-buffer
       :desc "code action"           "a" #'lsp-execute-code-action
       :desc "rename"                "r" #'lsp-rename))

  (with-eval-after-load 'js-ts-mode
    (scratch-javascript--def-localleader js-ts-mode-map))
  (with-eval-after-load 'typescript-ts-mode
    (scratch-javascript--def-localleader typescript-ts-mode-map))
  (with-eval-after-load 'tsx-ts-mode
    (scratch-javascript--def-localleader tsx-ts-mode-map)))

;;; Smartparens: template literal backticks

(with-eval-after-load 'smartparens
  (dolist (mode '(js-ts-mode typescript-ts-mode tsx-ts-mode))
    (sp-local-pair mode "`" "`"
                   :unless '(sp-in-comment-p sp-in-string-p))))

;;; Compilation: parse Node.js stack traces

(with-eval-after-load 'compile
  (add-to-list 'compilation-error-regexp-alist 'node)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(node "^[[:blank:]]*at \\(.*(\\|\\)\\(.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\)"
                 2 3 4)))
