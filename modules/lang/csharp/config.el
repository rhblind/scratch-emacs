;;; modules/lang/csharp/config.el -*- lexical-binding: t; -*-
;;
;; C# / .NET support. Uses the built-in `csharp-ts-mode' (tree-sitter
;; -based; Emacs 29+) for `.cs' files and remaps the older
;; `csharp-mode' to it. `dotnet' minor mode provides project-aware
;; build / run / test commands.
;;
;; LSP: when `:tools lsp' is enabled, `csharp-ts-mode' is in
;; `scratch-lsp-auto-modes' by default, so `lsp-deferred' attaches
;; on file open. Configure your LSP server (csharp-ls, omnisharp,
;; roslyn) in your config.org -- the framework doesn't pin a server
;; choice.

;; Tell `:editor tree-sitter' that we want the c-sharp grammar managed
;; by treesit-auto. The tree-sitter module unions `scratch-treesit-want'
;; into `treesit-auto-langs' on `emacs-startup-hook', which is what gates
;; the install-prompt path and `M-x treesit-auto-install-all'. No-op when
;; `:editor tree-sitter' isn't enabled.
(add-to-list 'scratch-treesit-want 'c-sharp)

;; Register the c-sharp grammar source as a fallback for users who don't
;; have `:editor tree-sitter' (treesit-auto otherwise provides this via
;; its recipe list). Lets `M-x treesit-install-language-grammar c-sharp'
;; and our helper work standalone.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp")))

;; Opt these modes into `:tools lsp' auto-attach. No-op when the lsp
;; module isn't enabled.
(when (modulep! :tools lsp)
  (dolist (mode '(csharp-ts-mode csharp-mode csproj-mode))
    (add-to-list 'scratch-lsp-auto-modes mode))
  (with-eval-after-load 'lsp-mode
    (add-to-list 'lsp-language-id-configuration '(csproj-mode . "xml")))
  (with-eval-after-load 'lsp-xml
    (setq lsp-xml-prefer-jar nil)))

;; Remap legacy `csharp-mode' to the tree-sitter mode -- but ONLY when
;; the grammar is actually available. Without the guard, csharp-ts-mode
;; loads and immediately fails with a `dlopen' warning (the `.so' file
;; doesn't exist), leaving the buffer in a broken state. With the guard,
;; missing-grammar machines fall back to CC-mode-based `csharp-mode',
;; which works fine -- and `scratch-csharp-install-grammar' (or the
;; one-time prompt below) gets the user onto csharp-ts-mode when ready.
(when (treesit-language-available-p 'c-sharp)
  (add-to-list 'major-mode-remap-alist '(csharp-mode . csharp-ts-mode)))

(defun scratch-csharp-install-grammar ()
  "Install the c-sharp tree-sitter grammar and switch to `csharp-ts-mode'.
Builds the grammar from upstream source (registered above in
`treesit-language-source-alist') and reverts the current buffer if
it's a `.cs' file so it picks up the tree-sitter mode immediately."
  (interactive)
  (treesit-install-language-grammar 'c-sharp)
  (add-to-list 'major-mode-remap-alist '(csharp-mode . csharp-ts-mode))
  (when (and buffer-file-name
             (string-match-p "\\.cs\\'" buffer-file-name))
    (revert-buffer nil t)))

(defvar scratch-csharp--grammar-prompted nil
  "Set once we've asked the user about installing the C# grammar this session.")

(defvar scratch-csharp--tree-sitter-module-p (modulep! :editor tree-sitter)
  "Non-nil when `:editor tree-sitter' is enabled. Captured at load time.")

(defun scratch-csharp--maybe-prompt-grammar-install ()
  "Offer (once) to install the c-sharp grammar on first `.cs' open.
Fallback path for users WITHOUT `:editor tree-sitter' -- when that
module is enabled, treesit-auto's own install prompt covers this
case (and prompting twice would be annoying). Idempotent: only
prompts the first time `csharp-mode' activates with a missing
grammar."
  (when (and (not scratch-csharp--grammar-prompted)
             (not scratch-csharp--tree-sitter-module-p)
             (eq major-mode 'csharp-mode)
             (not (treesit-language-available-p 'c-sharp)))
    (setq scratch-csharp--grammar-prompted t)
    (when (y-or-n-p "Install the C# tree-sitter grammar (better highlighting, structural editing, LSP)? ")
      (scratch-csharp-install-grammar))))

(add-hook 'csharp-mode-hook #'scratch-csharp--maybe-prompt-grammar-install)

;; Disable `prettify-symbols-mode' in C# buffers -- it mangles
;; operators (`=>' becomes a glyph that confuses paste / yank).
(defun scratch-csharp--no-prettify (&rest _)
  "`:before-while' advice on `prettify-symbols-mode': skip in C#."
  (not (or (eq major-mode 'csharp-mode)
           (eq major-mode 'csharp-ts-mode))))
(advice-add 'prettify-symbols-mode :before-while
            #'scratch-csharp--no-prettify)

;; `dotnet': minor mode that exposes `dotnet-run' / `dotnet-build' /
;; `dotnet-test' / `dotnet-add-package' etc. Activates lazily so it
;; doesn't slow down opening a `.cs' file.
(use-package dotnet
  :defer t
  :commands (dotnet-mode dotnet-run dotnet-build dotnet-test
             dotnet-restore dotnet-watch dotnet-add-package)
  :init
  (setq dotnet-project-search-max-depth 5)
  (defun scratch-csharp--activate-dotnet-mode-h ()
    "Turn on `dotnet-mode' once Emacs has been idle for a moment.
Avoids stalling file load while `dotnet-mode' resolves the project
root (which can be slow on large solutions)."
    (run-with-idle-timer
     1.0 nil
     (lambda ()
       (when (and (buffer-live-p (current-buffer))
                  (derived-mode-p 'csharp-ts-mode 'csharp-mode))
         (dotnet-mode 1)
         (setq-local dotnet-project-directory
                     (or (locate-dominating-file default-directory ".sln")
                         (locate-dominating-file default-directory ".csproj")
                         default-directory))))))
  (add-hook 'csharp-ts-mode-hook #'scratch-csharp--activate-dotnet-mode-h)
  (add-hook 'csharp-mode-hook    #'scratch-csharp--activate-dotnet-mode-h))

;; `.csproj' files get a dedicated mode; `.props' / `.targets' stay on
;; plain xml-mode since they're general MSBuild XML.
(use-package csproj-mode
  :mode "\\.csproj\\'")

(dolist (pat '("\\.props\\'" "\\.targets\\'"))
  (add-to-list 'auto-mode-alist `(,pat . xml-mode)))

;; CSharpier integration with apheleia. Apheleia ships a default
;; `csharpier' formatter that calls the global `csharpier' binary;
;; override to call `dotnet csharpier format --write-stdout' so the
;; per-project local tool install (`dotnet tool install csharpier'
;; in `.config/dotnet-tools.json') is preferred over the global one
;; -- mirrors the project-local `csharp-ls' resolution above.
(with-eval-after-load 'apheleia
  (setf (alist-get 'csharpier apheleia-formatters)
        '("dotnet" "csharpier" "format" "--write-stdout")))

;; LSP file-watching: the .NET build artifacts are huge and noisy. Ship
;; sensible ignores so opening a solution doesn't blow past
;; `lsp-file-watch-threshold' and so the file-system watcher isn't
;; pegged to no benefit. Patterns are anchored with `\\'' so they only
;; match the path tail, matching upstream's style.
(with-eval-after-load 'lsp-mode
  (dolist (pat '("[/\\\\]bin\\'"            ; per-project build output
                 "[/\\\\]obj\\'"            ; intermediates
                 "[/\\\\]packages\\'"       ; legacy NuGet packages dir
                 "[/\\\\]\\.vs\\'"          ; Visual Studio metadata
                 "[/\\\\]TestResults\\'"
                 "[/\\\\]artifacts\\'"      ; common monorepo build root
                 "[/\\\\]publish\\'"))
    (add-to-list 'lsp-file-watch-ignored-directories pat)))

;; Prefer a project-local `csharp-ls' (declared in
;; `.config/dotnet-tools.json' + `dotnet tool restore') over the global
;; install. Modern .NET repos pin tool versions per-project; respect
;; that. When no manifest declares csharp-ls, fall through to upstream's
;; lookup, which expects `csharp-ls' on PATH (the default location for
;; `dotnet tool install -g csharp-ls' is already on PATH on most setups).
;; Only fires when `lsp-csharp' loads, i.e. when csharp-ls is the chosen
;; server -- harmless for OmniSharp / Roslyn users.
(defun scratch-csharp--locate-project-root ()
  "Walk up from `default-directory' looking for a `.sln' / `.csproj' sibling.
`locate-dominating-file' takes a literal name, not a glob, so we pass
a predicate that scans each directory for matching extensions."
  (locate-dominating-file
   default-directory
   (lambda (dir)
     (and (file-directory-p dir)
          (directory-files dir nil "\\.\\(sln\\|csproj\\)\\'" t)))))

(defun scratch-csharp--project-has-local-csharp-ls-p ()
  "Non-nil if the current project declares csharp-ls as a local dotnet tool."
  (when-let* ((root (or (when (fboundp 'lsp-workspace-root)
                          (ignore-errors (lsp-workspace-root)))
                        (scratch-csharp--locate-project-root)))
              (manifest (expand-file-name ".config/dotnet-tools.json" root)))
    (when (file-exists-p manifest)
      (condition-case nil
          (let* ((json-object-type 'alist)
                 (json-array-type 'list)
                 (content (json-read-file manifest)))
            (assoc 'csharp-ls (alist-get 'tools content)))
        (error nil)))))

(defun scratch-csharp--cls-find-executable-a (&rest _)
  "`:before-until' advice on `lsp-csharp--cls-find-executable'.
Return the project-local dotnet-tool command when the project declares
csharp-ls; otherwise nil so upstream's PATH lookup runs."
  (when (scratch-csharp--project-has-local-csharp-ls-p)
    (list "dotnet" "tool" "run" "csharp-ls")))

(with-eval-after-load 'lsp-csharp
  (advice-add 'lsp-csharp--cls-find-executable :before-until
              #'scratch-csharp--cls-find-executable-a))

;; Localleader: dotnet ops on `,' / `M-,' inside C# buffers. Defined
;; once as a macro so we can install identically on both
;; `csharp-ts-mode-map' and the legacy `csharp-mode-map' without
;; reflection (`map!''s :map takes a literal keymap symbol).
(when (modulep! :editor leader)
  (defmacro scratch-csharp--def-localleader (mode-map)
    `(map! :map ,mode-map :localleader
       :desc "build"               "b" #'dotnet-build
       :desc "clean"               "c" #'dotnet-clean
       :desc "test"                "t" #'dotnet-test
       :desc "run"                 "r" #'dotnet-run
       :desc "run with args"       "A" #'dotnet-run-with-args
       :desc "restore"             "R" #'dotnet-restore
       :desc "publish"             "p" #'dotnet-publish
       :desc "new project"         "n" #'dotnet-new
       (:prefix-map ("a" . "add")
        :desc "package"            "p" #'dotnet-add-package
        :desc "reference"          "r" #'dotnet-add-reference)
       (:prefix-map ("s" . "solution")
        :desc "add project"        "a" #'dotnet-sln-add
        :desc "remove project"     "r" #'dotnet-sln-remove
        :desc "list projects"      "l" #'dotnet-sln-list
        :desc "new solution"       "n" #'dotnet-sln-new)
       (:prefix-map ("g" . "goto")
        :desc "csproj"             "p" #'dotnet-goto-csproj
        :desc "sln"                "s" #'dotnet-goto-sln)))

  (with-eval-after-load 'csharp-mode
    (scratch-csharp--def-localleader csharp-ts-mode-map)
    (scratch-csharp--def-localleader csharp-mode-map)))
