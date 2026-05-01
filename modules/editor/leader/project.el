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
  "p"   '(:ignore t                :which-key "project")
  "p p" '(project-switch-project   :which-key "switch project")
  "p l" '(scratch/list-projects    :which-key "list projects")
  "p f" '(project-find-file        :which-key "find file")
  "p b" '(project-switch-to-buffer :which-key "switch buffer")
  "p k" '(project-kill-buffers     :which-key "kill buffers")
  "p s" '(project-find-regexp      :which-key "search (regexp)")
  "p !" '(project-shell-command    :which-key "shell command")
  "p d" '(project-dired            :which-key "dired")
  "p F" '(project-forget-project   :which-key "forget project"))
