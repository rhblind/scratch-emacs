;;; modules/emacs/vc/config.el -*- lexical-binding: t; -*-
;;
;; Version control: built-in `vc' tweaks, magit (always), forge (with flag),
;; smerge-mode auto-enable, git-timemachine, browse-at-remote, git-modes.
;;
;; Adapted from Doom's :emacs vc, minus Doom-specific helpers
;; (`set-popup-rules!', `:localleader', `defadvice!') and the Emacs 31
;; vc-git--call signature compat hack.
;;
;; Flags:
;;   +forge  -- enable forge (GitHub / GitLab issues + PRs inside magit).
;;              Requires an authinfo entry for your forge token; see
;;              C-h f forge-add-repository.
;;   +gutter -- show VCS hunk indicators (added/modified/deleted) in the
;;              fringe (or margin in TTY) via diff-hl, with live updates
;;              before the file is saved (`diff-hl-flydiff-mode'). Adds
;;              hunk-navigation / stage / revert under `SPC g h'.

;;;; Built-in vc

;; Edit symlinks directly, don't auto-follow.
(setq vc-follow-symlinks nil)

;; Git only -- every backend in this list is probed for every TRAMP buffer
;; / file open, so trimming it pays.
(setq-default vc-handled-backends '(Git))

;; node_modules is huge; skip it for vc operations.
(setq-default vc-ignore-dir-regexp
              (format "%s\\|%s"
                      locate-dominating-stop-dir-regexp
                      "[/\\\\]node_modules"))

;;;; Magit

(use-package magit
  :defer t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :config
  (setq magit-diff-refine-hunk t
        magit-save-repository-buffers 'dontask
        magit-process-finish-apply-ansi-colors t
        magit-bury-buffer-function #'magit-mode-quit-window)

  (setq transient-display-buffer-action
        '(display-buffer-below-selected
          (dedicated . t)
          (inhibit-same-window . t)))

  (defun scratch-vc--setup-commit-window ()
    "Focus the commit buffer and auto-close its window on exit."
    (let ((buf (current-buffer)))
      (run-at-time 0 nil
        (lambda ()
          (when-let* (((buffer-live-p buf))
                      (win (get-buffer-window buf)))
            (select-window win)
            (set-window-dedicated-p win t)
            (with-current-buffer buf
              (add-hook 'kill-buffer-hook
                        (lambda ()
                          (when (and (window-live-p win)
                                     (not (one-window-p)))
                            (delete-window win)))
                        nil t)))))))

  (add-hook 'with-editor-mode-hook #'scratch-vc--setup-commit-window)
  ;; Upstream magit binds `Z' to `magit-worktree' on `magit-mode-map',
  ;; but in evil normal state `Z' is the vim save-and-quit prefix
  ;; (`ZZ' / `ZQ'), and evil-state maps win over mode-maps. evil-
  ;; collection only overrides `Z' here when `evil-collection-magit-
  ;; use-z-for-folds' is set, which we don't (we keep `z' for stash).
  ;; So restore magit's intended `Z' shortcut explicitly.
  (when (modulep! :editor evil)
    (with-eval-after-load 'evil
      (evil-define-key '(normal visual) magit-mode-map
        (kbd "Z") #'magit-worktree)))

  ;; After magit creates / switches to a worktree, jump to it via
  ;; `project-switch-project'. That's the same path `SPC p p' takes,
  ;; so it (a) goes through the workspaces module's advice (creates a
  ;; per-worktree persp), and (b) lands on the configured switch
  ;; action -- with `project-switch-commands' = `scratch/projects-find
  ;; -file', that's the vertico file picker scoped to the new
  ;; worktree. Deferred via `run-at-time 0' so the magit-status
  ;; window magit pops up first stays in the layout while the file
  ;; picker is up.
  (defun scratch-vc--worktree-then-pick-file-a (orig-fn directory &rest args)
    "Around-advice: run magit's worktree action, then pop the file picker."
    (apply orig-fn directory args)
    (when-let* ((dir (and directory
                          (file-directory-p (expand-file-name directory))
                          (file-name-as-directory (expand-file-name directory)))))
      (run-at-time 0 nil #'project-switch-project dir)))

  (dolist (cmd '(magit-worktree-checkout
                 magit-worktree-branch
                 magit-worktree-status))
    (advice-add cmd :around #'scratch-vc--worktree-then-pick-file-a)))

(defun scratch-vc--remove-stale-locks ()
  "Remove stale .lock files in .git/ when no git process is running."
  (when-let* ((topdir (magit-toplevel))
              (gitdir (expand-file-name ".git/" topdir)))
    (when (file-directory-p gitdir)
      (let ((git-running-p (cl-some
                            (lambda (p)
                              (and (process-live-p p)
                                   (string-match-p "\\bgit\\b" (process-name p))))
                            (process-list))))
        (unless git-running-p
          (dolist (lock (directory-files gitdir t "\\.lock\\'"))
            (delete-file lock)
            (message "Removed stale lock: %s" lock)))))))

(with-eval-after-load 'magit
  (add-hook 'magit-pre-refresh-hook #'scratch-vc--remove-stale-locks))

;;;; Worktree deletion cleanup

(defun scratch-vc--kill-buffers-in-directory (directory)
  "Kill all buffers whose file or default-directory is under DIRECTORY.
Uses string prefix matching so it works even after DIRECTORY is deleted."
  (let ((dir (file-name-as-directory (expand-file-name directory)))
        (killed 0))
    (dolist (buf (buffer-list))
      (when (buffer-live-p buf)
        (let* ((buf-file (buffer-file-name buf))
               (buf-dir (buffer-local-value 'default-directory buf))
               (expanded-file (and buf-file (expand-file-name buf-file)))
               (expanded-dir (and buf-dir
                                  (file-name-as-directory
                                   (expand-file-name buf-dir)))))
          (when (or (and expanded-file (string-prefix-p dir expanded-file))
                    (and expanded-dir (string-prefix-p dir expanded-dir)))
            (let ((kill-buffer-query-functions nil)
                  (confirm-kill-processes nil))
              (kill-buffer buf)
              (cl-incf killed))))))
    killed))

(defun scratch-vc--worktree-delete-cleanup-a (orig-fn worktree)
  "Around-advice: clean up buffers, workspace, and project after deletion."
  (let ((wt-dir (file-name-as-directory (expand-file-name worktree)))
        (wt-name (file-name-nondirectory (directory-file-name worktree))))
    (funcall orig-fn worktree)
    (let ((n (scratch-vc--kill-buffers-in-directory wt-dir)))
      (when (> n 0)
        (message "Killed %d buffer(s) from deleted worktree" n)))
    (when (and (modulep! :ui workspaces)
               (bound-and-true-p persp-mode)
               (member wt-name (scratch-workspaces--names)))
      (persp-kill wt-name)
      (scratch/workspace-display))
    (when (fboundp 'project-forget-project)
      (project-forget-project wt-dir))))

(with-eval-after-load 'magit
  (advice-add 'magit-worktree-delete :around
              #'scratch-vc--worktree-delete-cleanup-a))

;;;; git-commit -- commit message conventions

(with-eval-after-load 'git-commit
  (setq git-commit-summary-max-length 80
        git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line))

  ;; The stock `git-commit-run-post-finish-hook' blocks Emacs in a
  ;; tight `sit-for' loop while polling HEAD, freezing the UI until
  ;; the commit lands. Replace with a non-blocking timer.
  (defun scratch-vc--run-post-finish-hook-async (previous)
    "Non-blocking variant of `git-commit-run-post-finish-hook'.
Polls HEAD every 0.5s for up to 30s instead of blocking."
    (when git-commit-post-finish-hook
      (let ((attempts 0)
            (max-attempts 60)
            timer)
        (setq timer
              (run-with-timer
               0.5 0.5
               (lambda ()
                 (cond
                  ((not (equal (magit-rev-parse "HEAD") previous))
                   (cancel-timer timer)
                   (run-hooks 'git-commit-post-finish-hook))
                  ((>= (cl-incf attempts) max-attempts)
                   (cancel-timer timer)))))))))
  (advice-add 'git-commit-run-post-finish-hook :override
              #'scratch-vc--run-post-finish-hook-async)
  (add-hook 'git-commit-mode-hook
            (lambda () (setq-local fill-column 80)))
  (when (modulep! :editor evil)
    (add-hook 'git-commit-setup-hook
              (defun scratch-vc--commit-start-in-insert-state ()
                "Enter evil insert state when composing a blank commit message."
                (when (and (bound-and-true-p evil-local-mode)
                           (not (evil-emacs-state-p))
                           (bobp) (eolp))
                  (evil-insert-state))))))

;; magit-todos: surface project TODO / FIXME / HACK / etc. as a
;; section in `magit-status'. Keyword set is shared with hl-todo.
(use-package magit-todos
  :after magit
  :config
  (setq magit-todos-keyword-suffix "[: ]"     ; require ":" or " " after keyword
        magit-todos-max-items 50)
  (magit-todos-mode 1))

;; Forge -- GitHub / GitLab integration on top of magit.
(when (modulep! +forge)
  (use-package forge
    :after magit
    :init
    ;; Recent magit reorganized `magit-dispatch'; forge's auto-insert of
    ;; its "N Forge" suffix can't find its anchor key and emits a
    ;; "Cannot insert ... not found" warning. We don't need that auto
    ;; binding (forge commands are reachable via M-x and their own
    ;; bindings); turn the auto-bind off so forge never attempts it.
    (setq forge-add-default-bindings nil)))

;;;; Ediff -- keep everything in the current frame

(with-eval-after-load 'ediff
  (setq ediff-diff-options "-w"
        ediff-split-window-function #'split-window-horizontally
        ediff-window-setup-function #'ediff-setup-windows-plain)

  (defvar scratch-vc--ediff-saved-wconf nil)

  (add-hook 'ediff-before-setup-hook
    (defun scratch-vc--ediff-save-wconf ()
      (setq scratch-vc--ediff-saved-wconf (current-window-configuration))))

  (add-hook 'ediff-quit-hook
    (defun scratch-vc--ediff-restore-wconf ()
      (when (window-configuration-p scratch-vc--ediff-saved-wconf)
        (set-window-configuration scratch-vc--ediff-saved-wconf)))
    'append)
  (add-hook 'ediff-suspend-hook #'scratch-vc--ediff-restore-wconf 'append)

  (add-hook 'ediff-quit-hook
    (defun scratch-vc--ediff-refresh-magit ()
      (when (fboundp 'magit-refresh-all)
        (magit-refresh-all)))
    'append))

;;;; smerge -- auto-enable on conflict markers

(defun scratch-vc--maybe-enable-smerge ()
  "Enable `smerge-mode' if the buffer contains git conflict markers."
  (unless (bound-and-true-p smerge-mode)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " nil t)
        (smerge-mode 1)))))

(use-package smerge-mode
  :defer t
  :init
  (add-hook 'find-file-hook #'scratch-vc--maybe-enable-smerge)
  :config
  (which-key-add-key-based-replacements "C-c ^" "smerge")
  ;; Smerge actions on the localleader: SPC m n / , n / etc. when point is
  ;; in a buffer where smerge-mode is active.
  (when (modulep! :editor leader)
    (map! :map smerge-mode-map :localleader
          :desc "next conflict" "n"   #'smerge-next
          :desc "prev conflict" "p"   #'smerge-prev
          :desc "resolve"       "r"   #'smerge-resolve
          :desc "keep all"      "a"   #'smerge-keep-all
          :desc "keep base"     "b"   #'smerge-keep-base
          :desc "keep lower"    "l"   #'smerge-keep-lower
          :desc "keep upper"    "u"   #'smerge-keep-upper
          :desc "ediff"         "E"   #'smerge-ediff
          :desc "refine"        "R"   #'smerge-refine
          :desc "keep current"  "RET" #'smerge-keep-current)))

;;;; log-view -- evil-friendly j/k navigation between commits

(with-eval-after-load 'log-view
  (define-key log-view-mode-map (kbd "j") #'log-view-msg-next)
  (define-key log-view-mode-map (kbd "k") #'log-view-msg-prev))

;;;; vc-annotate -- q kills the buffer instead of burying it

(with-eval-after-load 'vc-annotate
  (define-key vc-annotate-mode-map [remap quit-window] #'kill-current-buffer))

;;;; git-timemachine -- step through file history

(use-package git-timemachine
  :defer t
  :config
  ;; Show revision details in the header-line as well so a stale timemachine
  ;; buffer is visually obvious.
  (setq git-timemachine-show-minibuffer-details t)

  ;; `delay-mode-hooks' suppresses font-lock-mode in newer Emacs; force it.
  (add-hook 'git-timemachine-mode-hook #'font-lock-mode)

  ;; Re-evaluate evil keymaps so timemachine bindings activate.
  (with-eval-after-load 'evil
    (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps)))

;;;; browse-at-remote

(use-package browse-at-remote
  :defer t
  :config
  ;; Prefer commit hashes (permalinks) over branch names.
  (setq browse-at-remote-prefer-symbolic nil
        ;; Don't auto-include the line number; require a region.
        browse-at-remote-add-line-number-if-no-region-selected nil)

  ;; Recognise codeberg.org and arbitrary gitlab.* hosts (Doom's tweaks).
  (add-to-list 'browse-at-remote-remote-type-regexps
               '(:host "^codeberg\\.org$" :type "codeberg"))
  (add-to-list 'browse-at-remote-remote-type-regexps
               '(:host "^gitlab\\." :type "gitlab") 'append))

;; browse-at-remote ships URLs for the current file / region but no
;; "open just the repo's homepage" command. Port Doom's two helpers:
;;   - `scratch/vc-browse-at-remote-homepage'      open homepage in browser
;;   - `scratch/vc-browse-at-remote-kill-homepage' copy homepage URL
;; Both ride on `browse-at-remote--remote-ref' to find the host base.

(defun scratch-vc--remote-homepage ()
  "Return the GitHub / GitLab / etc. homepage URL of the current repo."
  (require 'browse-at-remote)
  (or (let ((ref (browse-at-remote--remote-ref)))
        (plist-get (browse-at-remote--get-url-from-remote (car ref)) :url))
      (user-error "Can't find homepage for current project")))

(defun scratch/vc-browse-at-remote-homepage ()
  "Open the current project's repo homepage in the default browser."
  (interactive)
  (browse-url (scratch-vc--remote-homepage)))

(defun scratch/vc-browse-at-remote-kill-homepage ()
  "Copy the current project's repo homepage URL to the clipboard."
  (interactive)
  (let ((url (scratch-vc--remote-homepage)))
    (kill-new url)
    (message "Copied to clipboard: %s" url)))

;;;; git-modes (gitconfig-mode, gitignore-mode, gitattributes-mode)

(use-package git-modes :defer t)

;;;; diff-hl -- VCS hunk indicators (gated on +gutter)

(when (modulep! +gutter)
  (use-package diff-hl
    ;; Enable globally as soon as Emacs is up. `global-diff-hl-mode' is
    ;; autoloaded, so the hook itself will pull diff-hl in -- no separate
    ;; :defer / :commands plumbing needed.
    :hook (emacs-startup . global-diff-hl-mode)
    ;; Live updates without requiring a save; activates whenever
    ;; diff-hl-mode turns on in a buffer.
    :hook (diff-hl-mode  . diff-hl-flydiff-mode)
    ;; Same indicators inside dired listings.
    :hook (dired-mode    . diff-hl-dired-mode-unless-remote)
    ;; And inside vc-dir buffers.
    :hook (vc-dir-mode   . turn-on-diff-hl-mode)
    :init
    (setq vc-git-diff-switches '("--histogram")
          ;; Conservative refresh delay; default 0.3 trips on rapid edits.
          diff-hl-flydiff-delay 0.5
          ;; Realistic feedback: hunks vanish from the gutter as you stage.
          diff-hl-show-staged-changes nil
          ;; Skip image / pdf buffers -- nothing useful to show there.
          diff-hl-global-modes '(not image-mode pdf-view-mode))

    :config
    ;; TTY frames have no fringe; fall back to margin indicators.
    (unless (display-graphic-p)
      (diff-hl-margin-mode 1))

    ;; Update gutter when magit alters git state (commit, stage, stash, ...).
    ;; The stock `diff-hl-magit-post-refresh' has a path-comparison bug
    ;; (relative vs absolute) that silently skips buffers. Use a simpler
    ;; function that unconditionally refreshes every diff-hl buffer in the
    ;; repo.
    (defun scratch-vc--diff-hl-magit-update ()
      "Force diff-hl update in all file buffers within the current repo."
      (let ((topdir (magit-toplevel)))
        (dolist (buf (buffer-list))
          (when (and (buffer-local-value 'diff-hl-mode buf)
                     (buffer-file-name buf)
                     (not (file-remote-p (buffer-file-name buf)))
                     (file-in-directory-p (buffer-file-name buf) topdir))
            (with-current-buffer buf
              (when-let* ((backend (vc-backend buffer-file-name)))
                (vc-state-refresh buffer-file-name backend)
                (diff-hl-update)))))))
    (with-eval-after-load 'magit
      (add-hook 'magit-post-refresh-hook #'scratch-vc--diff-hl-magit-update))

    ;; Update gutter when Emacs regains focus (catches CLI commits, rebases,
    ;; etc. that happened in a terminal while Emacs was in the background).
    (add-function :after after-focus-change-function
                  (lambda ()
                    (when (frame-focus-state)
                      (diff-hl-update-once))))

    ;; Update gutter after vc-mode checkins (e.g. C-x v v).
    (add-hook 'vc-checkin-hook #'diff-hl-update)

    ;; Reverting a hunk shouldn't move point far from the hunk you targeted.
    (defun scratch-vc--diff-hl-revert-save-pt (orig-fn &rest args)
      (let ((pt (point)))
        (prog1 (apply orig-fn args)
          (goto-char pt))))
    (advice-add 'diff-hl-revert-hunk :around
                #'scratch-vc--diff-hl-revert-save-pt)))

;;;; Leader bindings (this module owns the SPC g submenu)

(when (modulep! :editor leader)
  (map! :leader
    (:prefix-map ("g" . "git")
     ;; -- top-level (Doom-shaped) --
     :desc "magit status"            "g" #'magit-status
     :desc "magit status here"       "G" #'magit-status-here
     :desc "magit dispatch"          "/" #'magit-dispatch
     :desc "magit file dispatch"     "." #'magit-file-dispatch
     :desc "branch checkout"         "b" #'magit-branch-checkout
     :desc "blame"                   "B" #'magit-blame-addition
     :desc "clone"                   "C" #'magit-clone
     :desc "delete file"             "D" #'magit-file-delete
     :desc "fetch"                   "F" #'magit-fetch
     :desc "log (buffer file)"       "L" #'magit-log-buffer-file
     :desc "revert file"             "R" #'vc-revert
     :desc "stage file"              "S" #'magit-file-stage
     :desc "unstage file"            "U" #'magit-file-unstage
     :desc "git timemachine"         "t" #'git-timemachine
     :desc "copy remote URL"         "y" #'browse-at-remote-kill
     :desc "copy homepage URL"       "Y" #'scratch/vc-browse-at-remote-kill-homepage
     ;; -- find --
     (:prefix-map ("f" . "find")
      :desc "magit find file"        "f" #'magit-find-file
      :desc "git config file"        "g" #'magit-find-git-config-file
      :desc "show commit"            "c" #'magit-show-commit)
     ;; -- list --
     (:prefix-map ("l" . "list")
      :desc "list repositories"      "r" #'magit-list-repositories
      :desc "list submodules"        "s" #'magit-list-submodules)
     ;; -- create --
     (:prefix-map ("c" . "create")
      :desc "init repo"              "r" #'magit-init
      :desc "clone repo"             "R" #'magit-clone
      :desc "commit"                 "c" #'magit-commit-create
      :desc "fixup commit"           "f" #'magit-commit-fixup
      :desc "branch"                 "b" #'magit-branch-and-checkout)
     ;; -- open in browser --
     (:prefix-map ("o" . "open in browser")
      :desc "browse file / region"   "o" #'browse-at-remote
      :desc "browse homepage"        "h" #'scratch/vc-browse-at-remote-homepage)))

  ;; +forge layer: extends `g f', `g o', `g l', `g c' with forge actions.
  (when (modulep! +forge)
    (map! :leader
      (:prefix-map ("g" . "git")
       :desc "forge dispatch"          "'" #'forge-dispatch
       (:prefix-map ("f" . "find")
        :desc "find issue"             "i" #'forge-visit-issue
        :desc "find pull request"      "p" #'forge-visit-pullreq)
       (:prefix-map ("o" . "open in browser")
        :desc "browse remote"          "r" #'forge-browse-remote
        :desc "browse commit"          "c" #'forge-browse-commit
        :desc "browse issue"           "i" #'forge-browse-issue
        :desc "browse pull request"    "p" #'forge-browse-pullreq
        :desc "browse issues"          "I" #'forge-browse-issues
        :desc "browse pull requests"   "P" #'forge-browse-pullreqs)
       (:prefix-map ("l" . "list")
        :desc "list issues"            "i" #'forge-list-issues
        :desc "list pull requests"     "p" #'forge-list-pullreqs
        :desc "list notifications"     "n" #'forge-list-notifications)
       (:prefix-map ("c" . "create")
        :desc "create issue"           "i" #'forge-create-issue
        :desc "create pull request"    "p" #'forge-create-pullreq))))

  ;; +gutter layer: hunk submenu under `g h'.
  (when (modulep! +gutter)
    (map! :leader
      (:prefix-map ("g" . "git")
       (:prefix-map ("h" . "hunk")
        :desc "next hunk"              "n" #'diff-hl-next-hunk
        :desc "prev hunk"              "p" #'diff-hl-previous-hunk
        :desc "next hunk"              "j" #'diff-hl-next-hunk
        :desc "prev hunk"              "k" #'diff-hl-previous-hunk
        :desc "stage hunk"             "s" #'diff-hl-stage-current-hunk
        :desc "revert hunk"            "r" #'diff-hl-revert-hunk
        :desc "show hunk"              "S" #'diff-hl-show-hunk
        :desc "set ref"                "R" #'diff-hl-set-reference-rev
        :desc "reset ref"              "X" #'diff-hl-reset-reference-rev)))))
