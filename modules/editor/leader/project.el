;;; modules/editor/leader/project.el -*- lexical-binding: t; -*-
;;
;; SPC p -- project leader bindings, plus a thin layer on top of
;; built-in project.el that mirrors the projectile UX (search path,
;; discover, cleanup, add). Loaded by leader/config.el.

(require 'cl-lib)

;;;; User-facing variables

(defvar scratch-projects-search-path nil
  "Directories under which to auto-discover projects.
Each entry is scanned on startup (and via `scratch/projects-discover')
for git repositories, which are then added to project.el's known list.

  (setq scratch-projects-search-path '(\"~/code\" \"~/work\"))

Override BEFORE calling `scratch!'.")

(defvar scratch-projects-search-depth 2
  "Subdirectory depth for scanning `scratch-projects-search-path' entries.
Larger values traverse deeper but take longer; 2 catches the typical
`<search-path>/<org>/<repo>' layout.")

;;;; Helpers

(defun scratch-projects--discover-1 (dir &optional depth)
  "Recursively register projects under DIR up to DEPTH levels deep."
  (require 'project)
  (let ((depth (or depth scratch-projects-search-depth))
        (count 0))
    (cl-labels
        ((walk (d remaining)
           (when (and (file-directory-p d)
                      (not (file-symlink-p d)))
             (cond
              ;; Found a project root -- register and stop descending.
              ((or (file-directory-p (expand-file-name ".git" d))
                   (file-exists-p   (expand-file-name ".git" d)))
               (project-remember-projects-under d nil)
               (cl-incf count))
              ;; Otherwise descend, but only while we still have budget.
              ((> remaining 0)
               (dolist (child (directory-files d t directory-files-no-dot-files-regexp))
                 (when (file-directory-p child)
                   (walk child (1- remaining)))))))))
      (walk (expand-file-name dir) depth))
    count))

;;;; Commands

(defun scratch/list-projects ()
  "Pick from the known projects via completing-read.
Uses the active completion stack (vertico picks this up automatically;
marginalia annotates with the resolved directory). Selecting a project
switches to it through `project-switch-project' so the workspaces
bridge runs as expected."
  (interactive)
  (require 'project)
  (let ((roots (project-known-project-roots)))
    (cond
     ((null roots)
      (user-error
       "No known projects yet -- try `SPC p D' (discover), `SPC p A' (add), or set `scratch-projects-search-path'"))
     (t
      (let ((choice (completing-read
                     (format "Project (%d known): " (length roots))
                     roots nil t)))
        (project-switch-project choice))))))

(defun scratch/projects-discover ()
  "Scan `scratch-projects-search-path' for git repos and add them.
Equivalent to projectile's `projectile-discover-projects-in-search-path'."
  (interactive)
  (cond
   ((null scratch-projects-search-path)
    (user-error "`scratch-projects-search-path' is empty -- nothing to scan"))
   (t
    (let ((added 0))
      (dolist (dir scratch-projects-search-path)
        (cl-incf added (scratch-projects--discover-1 dir)))
      (message "Discovered %d project%s under %d search path%s"
               added (if (= 1 added) "" "s")
               (length scratch-projects-search-path)
               (if (= 1 (length scratch-projects-search-path)) "" "s"))))))

(defun scratch/projects-cleanup ()
  "Forget known projects whose root directories no longer exist.
Equivalent to projectile's `projectile-cleanup-known-projects'."
  (interactive)
  (require 'project)
  (let* ((before (project-known-project-roots))
         (stale  (cl-remove-if #'file-directory-p before)))
    (cond
     ((null stale)
      (message "All %d known projects are present" (length before)))
     (t
      (dolist (root stale)
        (project-forget-project root))
      (message "Forgot %d stale project%s"
               (length stale) (if (= 1 (length stale)) "" "s"))))))

(defun scratch/projects-add (dir)
  "Add DIR itself to project.el's known projects list.
If project.el can identify a project type at DIR (via VCS or
`project-vc-extra-root-markers'), that type is used. Otherwise the
directory is force-added so it shows up in `SPC p p' / `SPC p l',
but most actions (find-file, etc.) will be limited until you give
the directory a marker (`git init', or set
`project-vc-extra-root-markers' to a file present in DIR like
`.project' or `config.org')."
  (interactive (list (read-directory-name "Add project: ")))
  (require 'project)
  (let* ((dir (file-name-as-directory (expand-file-name dir)))
         (proj (project--find-in-directory dir)))
    (cond
     (proj
      (project-remember-project proj)
      (message "Added project (%s): %s" (car proj) dir))
     (t
      (project--ensure-read-project-list)
      (unless (assoc dir project--list)
        (push (list dir) project--list)
        (project--write-project-list))
      (message
       "Added %s (no VCS / marker detected; run `git init' or set `project-vc-extra-root-markers')"
       dir)))))

(defun scratch/projects-find-file ()
  "Project-switch action: open `project-find-file' in the project we
just switched to. `project-switch-project' invokes us via
`call-interactively' (no args) after binding
`project-current-directory-override' to the chosen project, so a plain
call to `project-find-file' resolves correctly."
  (interactive)
  (project-find-file))

;;;; Project.el wiring

(with-eval-after-load 'project
  ;; Skip project.el's transient picker; jump straight to find-file
  ;; in the chosen project. Users who want the transient back can set
  ;; `project-switch-commands' to its default in their own config.
  (setq project-switch-commands #'scratch/projects-find-file)
  ;; Honour a `.project' marker file as a project root, so non-VCS
  ;; directories (e.g. ~/.scratch.d) become first-class with a single
  ;; `touch .project'. The default is empty.
  (add-to-list 'project-vc-extra-root-markers ".project"))

;; Auto-discover on startup, but only if the user has set a search
;; path -- otherwise keep startup quick.
(add-hook 'emacs-startup-hook
          (lambda ()
            (when scratch-projects-search-path
              (ignore-errors (scratch/projects-discover)))))

;;;; Leader bindings

(map! :leader
  (:prefix-map ("p" . "project")
   :desc "switch project"     "p" #'project-switch-project
   :desc "find file"          "f" #'project-find-file
   :desc "switch buffer"      "b" #'project-switch-to-buffer
   :desc "search (regexp)"    "s" #'project-find-regexp
   :desc "dired"              "d" #'project-dired
   :desc "kill buffers"       "k" #'project-kill-buffers
   :desc "shell command"      "!" #'project-shell-command
   :desc "list projects"      "l" #'scratch/list-projects
   :desc "discover projects"  "D" #'scratch/projects-discover
   :desc "cleanup stale"      "C" #'scratch/projects-cleanup
   :desc "add project"        "A" #'scratch/projects-add
   :desc "forget project"     "F" #'project-forget-project))
