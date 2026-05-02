;;; modules/editor/leader/project.el -*- lexical-binding: t; -*-
;;
;; SPC p -- project leader bindings (built-in project.el). Loaded by
;; leader/config.el.

(defun scratch/list-projects ()
  "Display known projects in a help buffer.
project.el doesn't ship a list command of its own; this is a thin
wrapper around `project-known-project-roots'."
  (interactive)
  (require 'project)
  (let ((roots (project-known-project-roots)))
    (if (null roots)
        (message "No known projects yet. Open a file in a project to register it.")
      (with-help-window "*Projects*"
        (princ "Known projects:\n\n")
        (dolist (root roots)
          (princ (format "  %s\n" root)))))))

(map! :leader
  (:prefix-map ("p" . "project")
   :desc "switch project"     "p" #'project-switch-project
   :desc "list projects"      "l" #'scratch/list-projects
   :desc "find file"          "f" #'project-find-file
   :desc "switch buffer"      "b" #'project-switch-to-buffer
   :desc "kill buffers"       "k" #'project-kill-buffers
   :desc "search (regexp)"    "s" #'project-find-regexp
   :desc "shell command"      "!" #'project-shell-command
   :desc "dired"              "d" #'project-dired
   :desc "forget project"     "F" #'project-forget-project))
