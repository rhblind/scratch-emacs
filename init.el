;;; init.el --- scratch framework init -*- lexical-binding: t; -*-
;;
;; Framework bootstrap. Topical setup lives under `lisp/' as
;; `scratch-<topic>.el' files; this file just dispatches to them and
;; then hands off to the user's literate config in $SCRATCHDIR
;; (default ~/.scratch.d/).

(require 'cl-lib)

(defvar scratch-emacs-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Path to the scratch framework dir (this repo).")

(defvar scratch-user-dir
  (file-name-as-directory
   (expand-file-name (or (getenv "SCRATCHDIR") "~/.scratch.d")))
  "Path to the user's config dir (analogue of DOOMDIR).")

(defvar scratch-lisp-dir
  (file-name-as-directory (expand-file-name "lisp" scratch-emacs-dir))
  "Path to the framework's `lisp/' directory.")

(add-to-list 'load-path scratch-lisp-dir)

;;; Shell-environment snapshot. `<user-emacs-directory>/env' is generated
;;; by the `scratch env' CLI command and contains a `read'-able list of
;;; `KEY=VALUE' strings captured from the user's shell. Loaded BEFORE
;;; straight (so git / curl / dotnet are findable on PATH) and BEFORE
;;; modules (so LSP servers, formatters, ripgrep are findable). Skip
;;; gracefully when absent -- env capture is opt-in.
(require 'scratch-env)
(scratch-load-envvars-file
 (expand-file-name "env" user-emacs-directory) 'noerror)

;;; straight.el bootstrap (https://github.com/radian-software/straight.el)
;;; Download tarballs instead of full git clones for faster initial install.
(setq straight-vc-use-snapshot-installation t)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;;; PERF: skip straight's `find(1)' modification probe at startup.
;;; The early-init setting gets clobbered by `defcustom''s reset on
;;; bootstrap; setting after the load form sticks. Without this,
;;; straight prints "Processing repository ..." for each repo and
;;; runs `find' across `straight/repos/' on every interactive launch.
;;; `check-on-save' catches in-Emacs edits via `before-save-hook';
;;; `bin/scratch sync' covers explicit refreshes.
(setq straight-check-for-modifications '(check-on-save find-when-checking))

;;; Lockfile syncing.
;;;
;;; straight writes its lockfile to <emacs-dir>/straight/versions/default.el,
;;; but the user's config repo is $SCRATCHDIR (default ~/.scratch.d/), so the
;;; canonical copy lives at $SCRATCHDIR/versions/default.el. Two pieces of
;;; advice keep them in sync transparently:
;;;
;;;   freeze  ->  framework copy written by straight, then copied to user dir
;;;   thaw    <-  user dir copy (if any) copied to framework dir before thaw
;;;
;;; This covers `scratch freeze', `scratch sync', and the interactive
;;; `M-x straight-freeze-versions' / `M-x straight-thaw-versions' paths.

(defvar scratch--framework-versions-file
  (expand-file-name "straight/versions/default.el"
                    (or (bound-and-true-p straight-base-dir)
                        user-emacs-directory))
  "Lockfile path inside the framework dir (where straight reads/writes).")

(defvar scratch--user-versions-file
  (expand-file-name "straight-lock.el" scratch-user-dir)
  "Lockfile path inside the user config dir (the canonical copy).")

(defun scratch--copy-lockfile (src dst)
  "Copy SRC to DST, creating parent directories as needed."
  (when (file-exists-p src)
    (let ((dir (file-name-directory dst)))
      (unless (file-directory-p dir)
        (make-directory dir t)))
    (copy-file src dst t)))

(define-advice straight-freeze-versions (:after (&rest _) scratch-copy-to-user-dir)
  "Copy the lockfile to the user config dir after freezing."
  (scratch--copy-lockfile scratch--framework-versions-file
                          scratch--user-versions-file))

(define-advice straight-thaw-versions (:before (&rest _) scratch-copy-from-user-dir)
  "Seed the framework lockfile from the user config dir before thawing."
  (scratch--copy-lockfile scratch--user-versions-file
                          scratch--framework-versions-file))

;;; Run thaw only in BATCH (`bin/scratch sync', CI, scripts). Interactive
;;; startups skip it because thaw walks every repo and re-applies its
;;; pinned SHA, adding noticeable latency. Workflow: pull config /
;;; lockfile changes, then `bin/scratch sync' to bring repos into line.
(when noninteractive
  (when (or (file-exists-p scratch--user-versions-file)
            (file-exists-p scratch--framework-versions-file))
    (straight-thaw-versions)))

;;; use-package, installed and used by default via straight
(straight-use-package 'use-package)
(require 'use-package)
(setq straight-use-package-by-default t)

;;; Tell straight to use Emacs's built-in `org' rather than cloning
;;; upstream. Must run BEFORE any package that lists `org' in
;;; `Package-Requires' (e.g. org-appear, org-superstar) gets installed --
;;; otherwise straight pulls upstream org as a transitive dependency,
;;; and the two versions clash on first org-mode buffer.
(straight-use-package '(org :type built-in))

;;; Customize output stays under user-emacs-directory (this framework dir).
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

;;; PERF: In interactive sessions, load the pre-built autoloads bundle
;;; (generated by `scratch sync'). This single file contains every
;;; package's load-path entry and autoload forms, replacing ~140
;;; individual file loads with one.
(require 'scratch-packages)
(unless noninteractive
  (scratch-packages-load-autoloads))



;;; Framework topical setup
(require 'scratch-modules)    ; scratch! / modulep! macros
(require 'scratch-defaults)   ; recentf, savehist, save-place, file/format defaults
(require 'scratch-keys)       ; general + the `map!' macro (framework-wide)
(require 'scratch-buffer)     ; buffer helpers (scratch/scratch-buffer, ...)
(require 'scratch-file)       ; file helpers (rename, copy, delete, sudo, yank path)
(require 'scratch-code)       ; prog-mode dispatchers (format, ...)
(require 'scratch-window)     ; window numbering + M-N bindings
(require 'scratch-mouse)      ; mouse support (GUI + TTY via xterm-mouse-mode)
(require 'scratch-treesit)    ; `scratch-treesit-want' (consumed by :editor tree-sitter)
(require 'scratch-vc)         ; `scratch-vc-worktree-dir-name' (consumed by :emacs vc, :tools lsp)
(require 'scratch-lsp)        ; `scratch-lsp-auto-modes' (consumed by :tools lsp)

;;; Tangle helper for the Local Variables `after-save-hook' at the end
;;; of config.org. Bare `org-babel-tangle' would normally suffice, but
;;; modern org skips rewriting an output file when the tangled content
;;; is byte-identical -- which leaves config.el / packages.el with an
;;; mtime older than the org file when you save structural changes
;;; (headings, prose) without editing any src blocks. The freshness
;;; check below would then warn on the next startup. Bumping the
;;; outputs to "now" after each tangle keeps mtime a reliable signal.
(defun scratch-tangle-config-org ()
  "Tangle the current org file and refresh output mtimes.
Used by the `after-save-hook' in $SCRATCHDIR/config.org so that the
freshness check in init.el sees outputs as in-sync, even when
`org-babel-tangle' skips writing unchanged outputs."
  (org-babel-tangle)
  (when-let* ((src (buffer-file-name))
              (dir (file-name-directory src)))
    (dolist (out '("config.el" "packages.el"))
      (let ((f (expand-file-name out dir)))
        (when (file-exists-p f) (set-file-times f))))))

;;; Literate user config: load the tangled outputs of $SCRATCHDIR/config.org.
;;; Tangling is NOT done at startup -- it happens via `scratch sync' (the
;;; canonical regenerate path) or via the `after-save-hook' set in the
;;; Local Variables block at the end of config.org. Loading `org' here
;;; would add seconds to cold-start for any non-trivial literate config.
;;; If the org file looks newer than the tangled outputs we just print a
;;; one-line nudge and load whatever's already on disk.
(let ((org      (expand-file-name "config.org"  scratch-user-dir))
      (config   (expand-file-name "config.el"   scratch-user-dir))
      (packages (expand-file-name "packages.el" scratch-user-dir)))
  ;; `noninteractive' is t when Emacs is started with `--batch' (every
  ;; `scratch' CLI subcommand does this). Skip the warning in that case
  ;; -- the user is already mid-sync, so telling them to sync is noise.
  (when (and (not noninteractive)
             (file-exists-p org)
             (or (and (file-exists-p config)   (file-newer-than-file-p org config))
                 (and (file-exists-p packages) (file-newer-than-file-p org packages))))
    ;; `message' echoes propertized text in both the echo area and the
    ;; *Messages* buffer; faces work in TTY too (mapped to the
    ;; nearest terminal colour).
    (message "%s %s config.org is newer than its tangled outputs -- run %s to refresh."
             (propertize "[scratch]" 'face 'font-lock-keyword-face)
             (propertize "warn:"     'face 'warning)
             (propertize "scratch sync" 'face 'font-lock-string-face)))
  (when (file-exists-p packages) (load packages nil 'nomessage))
  (when (file-exists-p config)   (load config   nil 'nomessage)))
