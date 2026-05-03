;;; modules/ui/workspaces/config.el -*- lexical-binding: t; -*-
;;
;; Workspaces via `persp-mode': named, isolated buffer sets with optional
;; per-workspace window configurations and on-disk session persistence.
;;
;; Modeled on Doom's :ui workspaces, trimmed to what doesn't depend on
;; Doom-specific helpers (`doom-buffer-list', `doom-fallback-buffer', the
;; popup system, projectile, ...). The result is a leaner persp-mode setup
;; that still gives you "main" as a default, file-based save/load, and
;; doom-modeline integration (which detects persp-mode automatically).

(defvar scratch-workspaces-main "main"
  "Name of the primary workspace, created on startup. Cannot be deleted.")

(defvar scratch-workspaces-save-dir
  (expand-file-name "workspaces/" user-emacs-directory)
  "Directory where persp-mode persists workspace state.")

(defvar scratch-workspaces--last nil
  "Name of the previously-active workspace (for `scratch/workspace-other').")

(use-package persp-mode
  :unless noninteractive
  :commands (persp-mode persp-switch-to-buffer)
  :hook (emacs-startup . persp-mode)
  :init
  (setq persp-keymap-prefix nil
        persp-nil-name "nil"
        persp-nil-hidden t
        persp-auto-resume-time -1   ; don't auto-load sessions on startup
        persp-auto-save-opt 1       ; save on Emacs exit
        persp-auto-save-fname "autosave"
        persp-save-dir scratch-workspaces-save-dir
        persp-set-last-persp-for-new-frames t
        persp-switch-to-added-buffer nil
        persp-reset-windows-on-nil-window-conf nil
        persp-autokill-buffer-on-remove 'kill-weak
        persp-kill-foreign-buffer-behaviour 'kill
        persp-remove-buffers-from-nil-persp-behaviour nil)
  :config
  ;; The default `nil' perspective is special and can't really hold buffers,
  ;; so we replace it with a real "main" perspective on startup.
  (defun scratch-workspaces--ensure-main (&rest _)
    (when persp-mode
      (let (persp-before-switch-functions)
        (unless (or (persp-get-by-name scratch-workspaces-main)
                    ;; persp-mode counts the nil workspace, so >2 means real ones exist
                    (> (hash-table-count *persp-hash*) 2))
          (persp-add-new scratch-workspaces-main))
        (dolist (frame (frame-list))
          (when (string= (safe-persp-name (get-current-persp frame))
                         persp-nil-name)
            (persp-frame-switch
             (or (cadr (hash-table-keys *persp-hash*))
                 scratch-workspaces-main)
             frame))))))
  (add-hook 'persp-mode-hook #'scratch-workspaces--ensure-main)
  (add-hook 'persp-after-load-state-functions #'scratch-workspaces--ensure-main)

  ;; `uniquify' rewrites buffer names, which confuses persp-mode's
  ;; name-based serialization across save/restore.
  (defvar scratch-workspaces--old-uniquify-style nil)
  (add-hook 'persp-mode-hook
            (lambda ()
              (cond (persp-mode
                     (when uniquify-buffer-name-style
                       (setq scratch-workspaces--old-uniquify-style
                             uniquify-buffer-name-style))
                     (setq uniquify-buffer-name-style nil)
                     ;; Make sure persp's kill-buffer hook runs last.
                     (remove-hook 'kill-buffer-query-functions
                                  #'persp-kill-buffer-query-function)
                     (add-hook 'kill-buffer-query-functions
                               #'persp-kill-buffer-query-function t))
                    (t
                     (when scratch-workspaces--old-uniquify-style
                       (setq uniquify-buffer-name-style
                             scratch-workspaces--old-uniquify-style))))))

  ;; Track previous workspace for `scratch/workspace-other'.
  (add-hook 'persp-before-switch-functions
            (lambda (new-persp-name &rest _)
              (let ((current (safe-persp-name (get-current-persp))))
                (unless (or (string= current persp-nil-name)
                            (string= current new-persp-name))
                  (setq scratch-workspaces--last current)))))

  ;; Don't try to persist dead/remote buffers; they error on restore.
  (add-hook 'persp-filter-save-buffers-functions
            (lambda (buf) (not (buffer-live-p buf))))
  (add-hook 'persp-filter-save-buffers-functions
            (lambda (buf)
              (let ((dir (buffer-local-value 'default-directory buf)))
                (ignore-errors (file-remote-p dir)))))

  ;; project.el integration: opening a project pops you into a workspace
  ;; named after that project. Mirrors persp-mode-projectile-bridge for
  ;; users coming from a Doom + projectile setup.
  (with-eval-after-load 'project
    (advice-add 'project-switch-project :around
                #'scratch-workspaces--project-switch-a)))


;;;; Helpers / commands

(defun scratch-workspaces--names ()
  "List of real workspace names (excluding the `nil' workspace)."
  (cl-remove persp-nil-name persp-names-cache :count 1 :test #'equal))

(defun scratch-workspaces--current-name ()
  (safe-persp-name (get-current-persp)))

(defun scratch-workspaces--protected-p (name)
  (equal name persp-nil-name))

(defun scratch/workspace-display ()
  "Echo a tab bar of the open workspaces."
  (interactive)
  (let* ((current (scratch-workspaces--current-name))
         (line (mapconcat
                (lambda (name)
                  (propertize (format " %s " name)
                              'face (if (equal current name)
                                        'highlight
                                      'default)))
                (scratch-workspaces--names)
                " ")))
    (let (message-log-max) (message "%s" line))))

(defun scratch-workspaces--known-project-root-by-name (name)
  "Return the project root whose basename matches workspace NAME, or nil.
Looks at `project.el's known-projects list. Used to keep the active
project in sync with the active workspace -- workspaces created by
`scratch-workspaces--project-switch-a' are named after the project's
basename, so this is the inverse lookup."
  (require 'project)
  (cl-find-if
   (lambda (root)
     (equal (scratch-workspaces--project-name root) name))
   (project-known-project-roots)))

(defun scratch-workspaces--ensure-in-project (root)
  "Ensure the visible buffer in the current workspace lives under ROOT.
If a workspace buffer is already inside ROOT, switch to it; else
fall back to opening ROOT in `dired'. No-op when the current buffer
is already inside ROOT (so we don't yank focus away from a buffer
that's already correct)."
  (unless (and default-directory
               (file-in-directory-p default-directory root))
    (let ((match (cl-find-if
                  (lambda (buf)
                    (when-let ((file (buffer-file-name buf)))
                      (file-in-directory-p file root)))
                  (persp-buffer-list))))
      (cond
       (match (switch-to-buffer match))
       (t (dired root))))))

(defun scratch/workspace-switch (name)
  "Switch to workspace NAME, prompting if called interactively.
When NAME matches a known project, also pulls the project context
along: the visible buffer is brought to one inside that project's
root (or `dired' on the root when the workspace has no project
buffers yet). This keeps `SPC p ...' commands targeting the
workspace's project after the switch."
  (interactive
   (list (completing-read "Switch to workspace: "
                          (scratch-workspaces--names))))
  (unless (member name (scratch-workspaces--names))
    (when (y-or-n-p (format "Workspace %S doesn't exist. Create it? " name))
      (persp-add-new name)))
  (persp-frame-switch name)
  (when-let ((root (scratch-workspaces--known-project-root-by-name name)))
    (scratch-workspaces--ensure-in-project root))
  (scratch/workspace-display))

(defun scratch/workspace-new (&optional name)
  "Create a new workspace. With NAME (or interactively with C-u), prompt."
  (interactive
   (list (when current-prefix-arg
           (read-string "New workspace name: "))))
  (let ((name (or name
                  (format "#%d"
                          (1+ (cl-loop for n in (scratch-workspaces--names)
                                       when (string-match "^#\\([0-9]+\\)$" n)
                                       maximize (string-to-number (match-string 1 n))
                                       into max
                                       finally return (or max 0)))))))
    (when (member name (scratch-workspaces--names))
      (user-error "Workspace %S already exists" name))
    (persp-add-new name)
    (persp-frame-switch name)
    (scratch/workspace-display)))

(defun scratch/workspace-new-named (name)
  "Create a new workspace named NAME."
  (interactive "sWorkspace name: ")
  (scratch/workspace-new name))

(defun scratch/workspace-rename (new-name)
  "Rename the current workspace to NEW-NAME."
  (interactive "sNew name: ")
  (let ((current (scratch-workspaces--current-name)))
    (when (scratch-workspaces--protected-p current)
      (user-error "Can't rename the %S workspace" current))
    (persp-rename new-name (get-current-persp))
    (message "Renamed %S -> %S" current new-name)))

(defun scratch/workspace-kill (&optional name)
  "Kill workspace NAME (defaults to current), then switch to a sibling."
  (interactive
   (list (if current-prefix-arg
             (completing-read "Kill workspace: "
                              (scratch-workspaces--names) nil t)
           (scratch-workspaces--current-name))))
  (let ((name (or name (scratch-workspaces--current-name)))
        (others (scratch-workspaces--names)))
    (when (scratch-workspaces--protected-p name)
      (user-error "Can't kill the %S workspace" name))
    (let ((siblings (remove name others)))
      (persp-kill name)
      (when siblings
        (persp-frame-switch
         (if (member scratch-workspaces--last siblings)
             scratch-workspaces--last
           (car siblings))))
      (scratch/workspace-display))))

(defun scratch/workspace-other ()
  "Switch to the previously-active workspace."
  (interactive)
  (cond ((null scratch-workspaces--last)
         (user-error "No previous workspace"))
        ((not (member scratch-workspaces--last (scratch-workspaces--names)))
         (user-error "Previous workspace %S no longer exists"
                     scratch-workspaces--last))
        (t (persp-frame-switch scratch-workspaces--last)
           (scratch/workspace-display))))

(defun scratch-workspaces--cycle (n)
  "Cycle N workspaces forward (negative N goes backward)."
  (let* ((names (scratch-workspaces--names))
         (count (length names)))
    (cond ((zerop count) (user-error "No workspaces"))
          ((= count 1) (user-error "Only one workspace"))
          (t (let* ((idx (or (cl-position (scratch-workspaces--current-name)
                                          names :test #'equal)
                             0))
                    (target (nth (mod (+ idx n) count) names)))
               (persp-frame-switch target)
               (scratch/workspace-display))))))

(defun scratch/workspace-next (&optional n)
  "Switch to the next workspace (cycling)."
  (interactive "p")
  (scratch-workspaces--cycle (or n 1)))

(defun scratch/workspace-prev (&optional n)
  "Switch to the previous workspace (cycling)."
  (interactive "p")
  (scratch-workspaces--cycle (- (or n 1))))

(defun scratch/workspace-switch-to-final ()
  "Switch to the last open workspace."
  (interactive)
  (when-let ((name (car (last (scratch-workspaces--names)))))
    (persp-frame-switch name)
    (scratch/workspace-display)))

(defun scratch/workspace-save (name)
  "Save workspace NAME to `persp-save-dir'."
  (interactive
   (list (completing-read "Save workspace: "
                          (scratch-workspaces--names) nil t
                          (scratch-workspaces--current-name))))
  (persp-save-state-to-file
   (expand-file-name (concat name ".persp") persp-save-dir)
   (list (persp-get-by-name name))
   t)
  (message "Saved workspace %S" name))

(defun scratch/workspace-load (name)
  "Load a previously-saved workspace from `persp-save-dir'."
  (interactive
   (list (completing-read
          "Load workspace: "
          (mapcar (lambda (f) (file-name-base f))
                  (directory-files persp-save-dir nil "\\.persp\\'")))))
  (persp-load-state-from-file
   (expand-file-name (concat name ".persp") persp-save-dir))
  (when (member name (scratch-workspaces--names))
    (persp-frame-switch name))
  (scratch/workspace-display))

(defun scratch-workspaces--project-name (directory)
  "Pick a workspace name from the project at DIRECTORY.
Uses the basename of DIRECTORY (e.g. `/path/to/foo/' -> `foo')."
  (file-name-nondirectory (directory-file-name (expand-file-name directory))))

(defun scratch-workspaces--workspace-empty-p (&optional name)
  "Non-nil if workspace NAME (defaults to current) has no buffers."
  (when-let ((persp (if name (persp-get-by-name name) (get-current-persp))))
    (null (persp-buffers persp))))

(defun scratch-workspaces--remember-project (directory)
  "Persist DIRECTORY to project.el's known list when it's a real project.
Workaround for `project-prompt-project-dir' only registering subdirs of
the entered path -- it never adds the path itself, so projects switched
to via `SPC p p' don't survive Emacs restarts."
  (when-let ((proj (project--find-in-directory
                    (file-name-as-directory (expand-file-name directory)))))
    (project-remember-project proj)))

(defun scratch-workspaces--project-switch-a (orig-fn directory)
  "Around-advice for `project-switch-project': route the switch through
a workspace named after the project. If the workspace already exists,
just switch to it (the project's last buffers come back). If we're
sitting in `scratch-workspaces-main' (or any empty workspace), recycle
that workspace by renaming it instead of leaving an empty shell behind.

Also registers DIRECTORY in project.el's known-projects list so it
sticks across restarts (project.el's own prompter only registers
subdirectories of the path you typed, not the path itself)."
  (scratch-workspaces--remember-project directory)
  (cond
   ((not (bound-and-true-p persp-mode))
    (funcall orig-fn directory))
   (t
    (let* ((name (scratch-workspaces--project-name directory))
           (current (scratch-workspaces--current-name)))
      (cond
       ;; Already in this project's workspace -- nothing to switch.
       ((equal current name)
        (funcall orig-fn directory))
       ;; Workspace already exists -- jump there, then run project action.
       ((member name (scratch-workspaces--names))
        (persp-frame-switch name)
        (funcall orig-fn directory))
       ;; Empty current workspace (e.g. fresh "main") -- recycle it.
       ((and (not (scratch-workspaces--protected-p current))
             (scratch-workspaces--workspace-empty-p))
        (persp-rename name (get-current-persp))
        (funcall orig-fn directory))
       ;; Otherwise, create a new workspace and switch.
       (t
        (persp-add-new name)
        (persp-frame-switch name)
        (funcall orig-fn directory)))))))


;; `dotimes' bodies define `scratch/workspace-switch-to-1' .. `-9'.
(dotimes (i 9)
  (let ((idx i))
    (defalias (intern (format "scratch/workspace-switch-to-%d" (1+ idx)))
      (lambda ()
        (interactive)
        (let ((names (scratch-workspaces--names)))
          (if-let ((target (nth idx names)))
              (progn (persp-frame-switch target)
                     (scratch/workspace-display))
            (user-error "No workspace at slot %d" (1+ idx)))))
      (format "Switch to workspace at slot %d." (1+ idx)))))


;;;; Leader bindings (this module owns SPC l)

(when (modulep! :editor leader)
  (map! :leader
    :desc "switch workspace buffer" "," #'persp-switch-to-buffer
    (:prefix-map ("l" . "workspace")
     ;; `l l' is the heavyweight: a completing-read selector
     ;; (vertico + marginalia surfaces it as a selectable list with
     ;; the current workspace marked). `l .' is an alias for muscle-
     ;; memory parity with Doom's `SPC TAB .'. The status-bar echo
     ;; (`scratch/workspace-display') stays callable via `M-x'; it's
     ;; rarely the thing you want from the leader.
     :desc "switch workspace"     "l"   #'scratch/workspace-switch
     :desc "switch workspace"     "."   #'scratch/workspace-switch
     :desc "switch to last"       "TAB" #'scratch/workspace-other
     :desc "new workspace"        "n"   #'scratch/workspace-new
     :desc "new (named)"          "N"   #'scratch/workspace-new-named
     :desc "rename workspace"     "r"   #'scratch/workspace-rename
     :desc "kill workspace"       "d"   #'scratch/workspace-kill
     :desc "save workspace"       "s"   #'scratch/workspace-save
     :desc "load workspace"       "L"   #'scratch/workspace-load
     :desc "next workspace"       "]"   #'scratch/workspace-next
     :desc "prev workspace"       "["   #'scratch/workspace-prev
     :desc "switch buffer (ws)"   "b"   #'persp-switch-to-buffer
     :desc "1st workspace"        "1"   #'scratch/workspace-switch-to-1
     :desc "2nd workspace"        "2"   #'scratch/workspace-switch-to-2
     :desc "3rd workspace"        "3"   #'scratch/workspace-switch-to-3
     :desc "4th workspace"        "4"   #'scratch/workspace-switch-to-4
     :desc "5th workspace"        "5"   #'scratch/workspace-switch-to-5
     :desc "6th workspace"        "6"   #'scratch/workspace-switch-to-6
     :desc "7th workspace"        "7"   #'scratch/workspace-switch-to-7
     :desc "8th workspace"        "8"   #'scratch/workspace-switch-to-8
     :desc "9th workspace"        "9"   #'scratch/workspace-switch-to-9
     :desc "final workspace"      "0"   #'scratch/workspace-switch-to-final)))
