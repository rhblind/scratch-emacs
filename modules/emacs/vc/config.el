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
  (setq magit-diff-refine-hunk t                  ; fine-grained diffs within hunks
        magit-save-repository-buffers 'dontask))  ; auto-save buffers, no prompt

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
    (with-eval-after-load 'magit
      (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

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
