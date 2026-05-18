;;; modules/tools/lsp/config.el -*- lexical-binding: t; -*-
;;
;; LSP via [[https://emacs-lsp.github.io/lsp-mode/][lsp-mode]] + lsp-ui (sideline / docs / peek) + consult-lsp
;; (when vertico is enabled). Companion modules light up automatically:
;;   - :ui treemacs already gates `lsp-treemacs' on `(modulep! :tools lsp)'
;;   - :checkers syntax keeps flycheck; lsp-mode plugs into it natively
;;
;; Server install / sessions live under user-emacs-directory so they
;; survive `straight/' wipes:
;;   ~/.config/emacs-scratch/lsp-servers/   -- downloaded language servers
;;   ~/.config/emacs-scratch/lsp-session    -- workspace state

;; `scratch-lsp-auto-modes' is defined in `lisp/scratch-lsp.el' (loaded
;; from init.el). Each `:lang' module pushes its modes there, so this
;; module never has to enumerate languages.

(use-package lsp-mode
  :commands (lsp lsp-deferred lsp-install-server)
  :init
  ;; Storage paths under user-emacs-directory (not inside straight/,
  ;; which would be wiped on a clean re-clone).
  (setq lsp-session-file (expand-file-name "lsp-session"
                                           user-emacs-directory)
        lsp-server-install-dir (expand-file-name "lsp-servers/"
                                                 user-emacs-directory))

  ;; Performance / sanity defaults (lifted from Doom's :tools lsp):
  (setq lsp-keep-workspace-alive nil      ; close server when last buffer dies
        lsp-enable-folding nil            ; folding via outline-minor-mode / treesit-fold
        lsp-enable-text-document-color nil
        lsp-enable-on-type-formatting nil
        lsp-headerline-breadcrumb-enable nil  ; redundant with modeline + imenu
        lsp-modeline-code-actions-enable nil  ; cluttery
        lsp-signature-auto-activate nil       ; opt-in via M-x
        ;; Don't bind `s-l' (or any global prefix); we wire SPC c bindings
        ;; via `map!' below, and the lsp internal keymap can be reached
        ;; via `lsp-keymap-prefix' if the user wants it.
        lsp-keymap-prefix nil
        ;; Plist data shape (faster, lower-memory). Must match the env
        ;; var set in packages.el.
        lsp-use-plists t
        ;; Quiet down: the JSON-RPC log is huge and rarely useful unless
        ;; debugging server protocol issues. `M-x lsp-toggle-trace-io'
        ;; flips it on demand.
        lsp-log-io nil
        ;; Idle work (workspace symbols, lens, ...) waits for a calm
        ;; editor. 0.5s feels responsive without spamming the server.
        lsp-idle-delay 0.5
        ;; Default file-watch threshold (1000) is well below what you
        ;; need for most monorepos. Raise generously; specific
        ;; languages add their own ignore patterns (see e.g.
        ;; `:lang csharp' for .NET artifacts) so the count stays sane.
        lsp-file-watch-threshold 1000000
        ;; Default 0.5s is too short for cold-started servers (csharp-ls
        ;; restoring a big solution, pyright indexing a monorepo) -- a
        ;; brief sync request would time out and surface as a warning.
        lsp-response-timeout 10)

  ;; corfu is the framework's in-buffer completion UI. Tell lsp-mode to
  ;; not autoconfigure company-mode (which would warn "Unable to
  ;; autoconfigure company-mode" on every connect, since we don't ship
  ;; company). `:none' makes lsp set up `completion-at-point-functions'
  ;; and stops there -- corfu picks the CAPF up natively.
  (when (modulep! :completion corfu)
    (setq lsp-completion-provider :none)
    (add-hook 'lsp-mode-hook #'lsp-completion-mode))

  ;; Yasnippet integration: enable only when the snippets module is
  ;; loaded; otherwise lsp-mode warns "Yasnippet is not installed, but
  ;; `lsp-enable-snippet' is set to `t'" on every connect.
  (setq lsp-enable-snippet (modulep! :editor snippets))

  ;; Auto-enable lsp in the modes the user has opted into.
  (dolist (mode scratch-lsp-auto-modes)
    (let ((hook (intern (format "%s-hook" mode))))
      (add-hook hook #'lsp-deferred)))

  ;; Drop opt-in lsp clients we never want to talk to. lsp-mode's
  ;; `lsp-client-packages' is the list of client modules it `require's
  ;; lazily on demand; pruning here means the client never gets loaded,
  ;; never registers, never gets picked. Each entry is a package
  ;; (feature) name like `lsp-semgrep' / `lsp-terraform'.
  ;;
  ;; - `lsp-semgrep' phones home to https://semgrep.dev/c/p/default to
  ;;   download a default ruleset on every start; on flaky networks
  ;;   this hangs lsp-mode for 10s+ per request and bricks workspaces.
  ;;   Users who actually want semgrep can re-add it in their config:
  ;;     (add-to-list 'lsp-client-packages 'lsp-semgrep)
  (with-eval-after-load 'lsp-mode
    (dolist (client '(lsp-semgrep))
      (setq lsp-client-packages (delq client lsp-client-packages))))

  ;; Don't watch files inside `.worktrees/' subdirectories. The
  ;; framework convention puts git worktrees under
  ;; `.worktrees/<branch>/' inside the main repo, but each worktree
  ;; is itself a complete checkout -- file watchers that descend into
  ;; them are wasted work. `lsp-file-watch-ignored-directories' only
  ;; controls Emacs-side file watchers; it does NOT tell the LSP
  ;; server to skip those paths. Many servers index the workspace
  ;; root regardless of what the client says, so worktree files come
  ;; back in xref / peek results. We handle that with the response-
  ;; filter advice below -- universal, language-server-agnostic.
  (with-eval-after-load 'lsp-mode
    (dolist (pat '("[/\\\\]\\.worktrees\\'"
                   "[/\\\\]\\.worktrees[/\\\\]"))
      (add-to-list 'lsp-file-watch-ignored-directories pat))))

;; ---------------------------------------------------------------------------
;; Universal worktree filter for LSP responses.
;;
;; Per-server `excludePaths' / `excludePatterns' configs are too varied
;; to maintain (every LSP has its own format, some don't expose one).
;; Instead, filter at the client-side conversion layer: when LSP returns
;; a list of `Location' / `LocationLink' objects (references, defs,
;; impls, peek results, ...), drop entries that don't belong to the
;; current buffer's worktree. Works for ANY LSP server.
;;
;; Bidirectional:
;;   - From the main repo: drops results under `<main>/.worktrees/.../'.
;;   - From a worktree:    drops results in the main repo (and in
;;                          sibling worktrees).
;; External paths (libraries outside the tree-group) are always kept --
;; jump-to-definition into a dependency under `~/.cache/...' or `_build'
;; still works.

(defvar scratch-lsp-worktree-dir-name ".worktrees"
  "Directory name (relative to the main repo) that holds git worktrees.
Used by the LSP response filter to identify the worktree-group root.
Defaults to `.worktrees', matching the framework convention.")

(defun scratch-lsp--location-uri (loc)
  "Return the URI string for a Location / LocationLink LOC, or nil."
  (or (ignore-errors (lsp:location-uri loc))
      (ignore-errors (lsp:location-link-target-uri loc))))

(defun scratch-lsp--scope-for-path (path)
  "Return (MAIN-ROOT . WORKTREE-LABEL) describing PATH's worktree scope.

MAIN-ROOT is the directory above `.worktrees/' (i.e. the main repo).
WORKTREE-LABEL is the immediate worktree subdir name, or nil when
PATH is in the main repo. Returns nil when PATH isn't part of a
worktree-organized project at all (no `.worktrees/' anywhere visible)."
  (when path
    (let* ((expanded (expand-file-name path))
           (worktree-re (concat "\\(.*?\\)/"
                                (regexp-quote scratch-lsp-worktree-dir-name)
                                "/\\([^/]+\\)\\(?:/\\|\\'\\)")))
      (cond
       ;; Path is INSIDE `<main>/.worktrees/<X>/'.
       ((string-match worktree-re expanded)
        (cons (file-name-as-directory (match-string 1 expanded))
              (match-string 2 expanded)))
       ;; Path's parent dir has a `.worktrees/' sibling -- main repo.
       ((when-let* ((dir (file-name-directory expanded))
                    (root (locate-dominating-file
                           dir scratch-lsp-worktree-dir-name)))
          (cons (file-name-as-directory (expand-file-name root)) nil)))))))

(defun scratch-lsp--keep-location-p (path our-main our-label)
  "Return non-nil when PATH should be kept given the buffer's scope.
OUR-MAIN is the buffer's main-repo root (with trailing slash), OUR
-LABEL is the buffer's worktree subdir name (or nil for main-repo)."
  (let ((p (expand-file-name path))
        (worktree-prefix (concat (file-name-as-directory our-main)
                                 scratch-lsp-worktree-dir-name "/")))
    (cond
     ;; External path (library, dependency, ...) -- keep.
     ((not (string-prefix-p our-main p)) t)
     ;; Inside `.worktrees/'.
     ((string-prefix-p worktree-prefix p)
      (and our-label
           (string-prefix-p (concat worktree-prefix our-label "/") p)))
     ;; Inside the tree-group root, not under `.worktrees/' -- main.
     (t (null our-label)))))

(defun scratch-lsp--filter-worktree-locations (locations)
  "Drop LOCATIONS that don't belong to the current buffer's worktree.
LOCATIONS may be a list, vector, or singleton; returns a list."
  (let ((buffer-path (or buffer-file-name
                         (and (eq major-mode 'dired-mode) default-directory))))
    (cond
     ((null buffer-path) locations)
     (t
      (let ((our-scope (scratch-lsp--scope-for-path buffer-path)))
        (if (null our-scope)
            ;; Not in a worktree-organized project; nothing to filter.
            locations
          (let ((our-main (car our-scope))
                (our-label (cdr our-scope))
                (locs (cond ((vectorp locations) (append locations nil))
                            ((listp locations)   locations)
                            (t                   (list locations)))))
            (cl-remove-if-not
             (lambda (loc)
               (when-let* ((uri (scratch-lsp--location-uri loc))
                           (path (lsp--uri-to-path uri)))
                 (scratch-lsp--keep-location-p path our-main our-label)))
             locs))))))))

(with-eval-after-load 'lsp-mode
  ;; Covers `lsp-find-references' / `lsp-find-definition' / `lsp-find-
  ;; implementation' / etc. (and anything else that routes through
  ;; xref). Filter the Location[] before lsp-mode converts to xref items.
  (advice-add 'lsp--locations-to-xref-items :filter-args
              (lambda (args)
                (list (scratch-lsp--filter-worktree-locations (car args))))))

;; ---------------------------------------------------------------------------
;; Worktree-aware workspace-root resolution.
;;
;; `lsp-workspace-root' picks the longest path in `lsp-session-folders'
;; that is an ancestor of the file. When you open a git worktree
;; (`<main>/.worktrees/<branch>/...') *after* opening the main repo,
;; `<main>' is in session-folders but `<main>/.worktrees/<branch>/' is
;; NOT, so lsp matches `<main>' and reuses its server -- both the main
;; repo and the worktree end up rooted at the same path, which defeats
;; the response-filter above and pollutes diagnostics across copies.
;;
;; Fix: before lsp computes a root for a buffer, ensure the buffer's
;; worktree path (if any) is in `lsp-session-folders'. Then upstream's
;; "longest ancestor wins" picks the worktree, lsp starts a fresh
;; server for it, and the two trees stay isolated end-to-end.

(defun scratch-lsp--ensure-worktree-folder (&rest _)
  "Add the buffer's worktree root to `lsp-session-folders' if applicable.
A no-op when the current buffer isn't inside a `<main>/.worktrees/<branch>/'
path, or when that path is already a session folder.

Uses `lsp-workspace-folders-add' (the public API) rather than mutating
the session struct directly -- the public path also persists the
session and runs the workspace-folders-changed hooks."
  (when-let* ((path buffer-file-name)
              (scope (scratch-lsp--scope-for-path path))
              (main  (car scope))
              (label (cdr scope))
              (worktree (file-name-as-directory
                         (concat main scratch-lsp-worktree-dir-name "/" label)))
              ((fboundp 'lsp-session))
              ((fboundp 'lsp-workspace-folders-add))
              (current (lsp-session-folders (lsp-session))))
    (unless (member worktree current)
      (lsp-workspace-folders-add worktree))))

(with-eval-after-load 'lsp-mode
  ;; `lsp' and `lsp-deferred' are the two entry points that resolve a
  ;; root; advise both. `:before' runs before root computation so the
  ;; worktree path is on the candidate list when lsp picks the longest
  ;; ancestor.
  (advice-add 'lsp          :before #'scratch-lsp--ensure-worktree-folder)
  (advice-add 'lsp-deferred :before #'scratch-lsp--ensure-worktree-folder))

(with-eval-after-load 'lsp-ui-peek
  ;; lsp-ui-peek has its own response handler that bypasses
  ;; `lsp--locations-to-xref-items'. Its return value is a list of
  ;; plists `(:file PATH :xrefs (...))', already grouped by file.
  ;; Drop groups whose `:file' isn't in our worktree.
  (advice-add 'lsp-ui-peek--get-references :filter-return
              (lambda (groups)
                (when-let* ((buffer-path (buffer-file-name))
                            (scope (scratch-lsp--scope-for-path buffer-path)))
                  (let ((our-main (car scope))
                        (our-label (cdr scope)))
                    (setq groups
                          (cl-remove-if-not
                           (lambda (g)
                             (when-let ((file (plist-get g :file)))
                               (scratch-lsp--keep-location-p
                                file our-main our-label)))
                           groups))))
                groups)))

;; ---------------------------------------------------------------------------
;; Performance: GC + IPC tuning while LSP is in use.
;;
;; lsp-mode ferries large JSON payloads through the subprocess pipe and
;; allocates a lot under hood. Two knobs make this dramatically nicer:
;;   - `read-process-output-max' caps the bytes lsp-mode pulls per read.
;;     The default (4KB on most systems) splits replies into many tiny
;;     reads. Bumping to 1MB lets one read swallow most messages.
;;   - `gc-cons-threshold' default (~800KB) triggers a full GC mid-RPC.
;;     Bumping while LSP is alive trades memory headroom for fewer GC
;;     pauses. Restore on uninitialize so the rest of Emacs gets the
;;     normal collection cadence.
;;
;; Adapted from Doom's `+lsp-optimization-mode'.

(defvar scratch-lsp--saved-rpo nil)
(defvar scratch-lsp--saved-gc nil)
(defvar scratch-lsp--optimized nil)

(define-minor-mode scratch-lsp-optimization-mode
  "GC + IPC optimizations applied while lsp-mode is active."
  :global t :init-value nil
  (cond
   (scratch-lsp-optimization-mode
    (unless scratch-lsp--optimized
      (setq scratch-lsp--saved-rpo (default-value 'read-process-output-max)
            scratch-lsp--saved-gc  (default-value 'gc-cons-threshold))
      (setq-default read-process-output-max (* 1024 1024)  ; 1 MB
                    gc-cons-threshold       (* 64 1024 1024)) ; 64 MB
      (setq scratch-lsp--optimized t)))
   (t
    (when scratch-lsp--optimized
      (setq-default read-process-output-max scratch-lsp--saved-rpo
                    gc-cons-threshold       scratch-lsp--saved-gc)
      (setq scratch-lsp--optimized nil)))))

(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-before-initialize-hook #'scratch-lsp-optimization-mode)
  (add-hook 'lsp-after-uninitialized-functions
            (lambda (_)
              ;; Disable optimizations only when no workspaces remain.
              (unless (and (boundp 'lsp--session)
                           lsp--session
                           (lsp--session-workspaces lsp--session))
                (scratch-lsp-optimization-mode -1)))))

;; ---------------------------------------------------------------------------
;; Performance: defer workspace shutdown.
;;
;; When the last buffer for a workspace closes, lsp-mode normally tears
;; the server down immediately (because we set `lsp-keep-workspace-alive'
;; nil above). On big projects (csharp-ls indexing a .NET solution,
;; pyright loading a large monorepo) the restart cost is seconds. Defer
;; the teardown so revert-buffer / quick file-jump don't trigger it.
;;
;; Adapted from Doom's `+lsp-defer-server-shutdown-a'.

(defvar scratch-lsp-defer-shutdown 3
  "Seconds to wait before shutting down a workspace with no live buffers.
0 disables (immediate shutdown). nil disables the advice entirely.")

(defvar scratch-lsp--shutdown-timer nil)

(defun scratch-lsp--defer-shutdown-a (fn &optional restart)
  "Around-advice for `lsp--shutdown-workspace': defer when buffers reopen quickly."
  (if (or lsp-keep-workspace-alive
          restart
          (null scratch-lsp-defer-shutdown)
          (= scratch-lsp-defer-shutdown 0))
      (funcall fn restart)
    (when (timerp scratch-lsp--shutdown-timer)
      (cancel-timer scratch-lsp--shutdown-timer))
    (setq scratch-lsp--shutdown-timer
          (run-at-time
           scratch-lsp-defer-shutdown nil
           (lambda (workspaces)
             (dolist (ws workspaces)
               (unless (cl-some #'lsp-buffer-live-p
                                (lsp--workspace-buffers ws))
                 (with-lsp-workspace ws
                   (let ((lsp-restart 'ignore))
                     (funcall fn))))))
           lsp--buffer-workspaces))))

(with-eval-after-load 'lsp-mode
  (advice-add 'lsp--shutdown-workspace :around
              #'scratch-lsp--defer-shutdown-a))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :init
  (setq lsp-ui-doc-show-with-cursor nil   ; only on `M-x lsp-ui-doc-show'
        lsp-ui-doc-show-with-mouse nil    ; otherwise disappears on hover
        lsp-ui-doc-max-height 8           ; tall doc popups eat the screen
        lsp-ui-doc-max-width 72           ; default 150 is too wide
        lsp-ui-doc-delay 0.75             ; 0.2 is naggy
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-ignore-duplicate t
        lsp-ui-sideline-show-code-actions nil  ; cluttery in the gutter
        lsp-ui-sideline-show-hover nil         ; ditto, plus hides flycheck
        lsp-ui-peek-enable t))            ; `c l G {g,i,r,s}' surfaces these

(use-package consult-lsp
  :when (modulep! :completion vertico)
  :after (lsp-mode consult)
  :commands (consult-lsp-symbols
             consult-lsp-file-symbols
             consult-lsp-diagnostics))

;;;; Leader bindings under `SPC c' (code prefix).
;;
;; Layers on top of `:editor leader/code.el's baselines (which use
;; xref / generic Emacs commands), overriding with LSP-aware variants
;; when an LSP server is attached. Conventions match Doom's `SPC c':
;;   c d / c D    jump to definition / references
;;   c i / c t    find implementation / type definition
;;   c k / c K    describe symbol / lsp-ui doc popup
;;   c r / c a    rename / code action
;;   c o          organize imports
;;   c f / c F    format buffer / region
;;   c j / c J    workspace symbols / all-workspaces (vertico)
;;   c s / c X    file symbols / diagnostics (vertico)
;;   c l          full upstream `lsp-command-map' as a sub-prefix
;;
;; The peek variants (`lsp-ui-peek-find-*') and the workspace
;; toggles / folder mgmt / etc. live under `c l' (i.e. via the
;; `lsp-command-map' sub-prefix) -- run `SPC c l' and which-key shows
;; the menu.

(defun scratch-lsp/consult-symbols-all-workspaces ()
  "Run `consult-lsp-symbols' across all workspaces."
  (interactive)
  (consult-lsp-symbols 'all-workspaces))

;; Evil `K' (look up doc at point) -- set `evil-lookup-func' per-buffer
;; when LSP is attached so it shows server-side hover info in *Help*.
;; Outside LSP buffers evil's default K behavior is preserved.
(when (modulep! :editor evil)
  (add-hook 'lsp-mode-hook
            (lambda ()
              (setq-local evil-lookup-func #'lsp-describe-thing-at-point))))

(when (modulep! :editor leader)
  (with-eval-after-load 'lsp-mode
    ;; LSP-only commands. The xref-based baselines (`c d', `c D',
    ;; `c i') already route through lsp-mode's xref backend when
    ;; LSP is attached, so don't override them. Same for `c k'
    ;; (smart wrapper) and `c f' (smart wrapper).
    (map! :leader
          (:prefix-map ("c" . "code")
                       :desc "find type definition" "t" #'lsp-find-type-definition
                       :desc "lsp-ui doc popup"     "K" #'lsp-ui-doc-show
                       :desc "code action"          "a" #'lsp-execute-code-action
                       :desc "rename symbol"        "r" #'scratch/rename
                       :desc "organize imports"     "o" #'lsp-organize-imports))
    ;; `+peek' bindings are wired below at the top level (outside this
    ;; `with-eval-after-load 'lsp-mode' body) because `modulep!' on a
    ;; flag reads the dynamic `scratch--current-module', which is only
    ;; bound while a module's `config.el' is being loaded. By the time
    ;; this `with-eval-after-load' body fires, that binding is gone.

    ;; `SPC c l' as a sub-prefix into upstream's full `lsp-command-map'
    ;; (workspaces / folders / toggles / goto / peeks / refactoring).
    ;; Bound via raw `general-define-key' because `map!''s `:desc'
    ;; helper would wrap the keymap symbol into general's extended-def
    ;; form, which then treats it as a command instead of a prefix.
    (general-define-key
     :prefix scratch-leader-key
     :non-normal-prefix scratch-leader-non-normal-key
     :states '(normal visual motion emacs insert)
     :keymaps 'override
     "c l" `(,lsp-command-map :which-key "lsp"))
    ;; Label the sub-prefixes inside `lsp-command-map' so which-key
    ;; shows "workspaces" / "goto" / "peeks" / etc. instead of the
    ;; generic "+prefix" placeholder. lsp-mode ships its own helper
    ;; (`lsp-enable-which-key-integration') which registers labels via
    ;; `which-key-add-key-based-replacements' under whatever prefix
    ;; `lsp-keymap-prefix' is bound to -- temporarily rebind it to our
    ;; leader path so the labels land at `SPC c l ...'. This mirrors
    ;; Doom's `+default/lsp-command-map'.
    (when (fboundp 'lsp-enable-which-key-integration)
      (let ((lsp-keymap-prefix (concat scratch-leader-key " c l")))
        (lsp-enable-which-key-integration t)))
    ;; Consult-driven pickers when vertico is in.
    (when (modulep! :completion vertico)
      (map! :leader
            (:prefix-map ("c" . "code")
                         :desc "workspace symbols"               "j" #'consult-lsp-symbols
                         :desc "workspace symbols (all)"         "J" #'scratch-lsp/consult-symbols-all-workspaces
                         :desc "file symbols"                    "s" #'consult-lsp-file-symbols
                         :desc "diagnostics"                     "X" #'consult-lsp-diagnostics)))))

;; `+peek' bindings. Top-level so `(modulep! +peek)' resolves while
;; `scratch--current-module' is still bound to this module's entry
;; (the flag predicate is dynamic). Routes the navigation triplet
;; `c d' / `c D' / `c i' through `lsp-ui-peek' (inline popup) instead
;; of xref's jump-and-buffer UX, plus `c S' for workspace-symbol peek.
(when (and (modulep! :editor leader) (modulep! +peek))
  (with-eval-after-load 'lsp-ui-peek
    (map! :leader
          (:prefix-map ("c" . "code")
                       :desc "peek definitions"      "d" #'lsp-ui-peek-find-definitions
                       :desc "peek references"       "D" #'lsp-ui-peek-find-references
                       :desc "peek implementations"  "i" #'lsp-ui-peek-find-implementation
                       :desc "peek workspace symbol" "S" #'lsp-ui-peek-find-workspace-symbol))
    ;; Inside the peek popup: j/k for next/prev, C-j/C-k for
    ;; next-file/prev-file. Evil-friendly; mirrors Doom.
    (map! :map lsp-ui-peek-mode-map
          "j"   #'lsp-ui-peek--select-next
          "k"   #'lsp-ui-peek--select-prev
          "C-j" #'lsp-ui-peek--select-next-file
          "C-k" #'lsp-ui-peek--select-prev-file)))
