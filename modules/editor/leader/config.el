;;; modules/editor/leader/config.el -*- lexical-binding: t; -*-
;;
;; Leader key infrastructure: SPC-prefixed transient menus (Doom / Spacemacs
;; style) backed by general.el for declarative bindings and which-key for the
;; discovery popup.
;;
;; Overrides (set BEFORE calling `scratch!'):
;;   scratch-leader-key            -- default "SPC"   (normal/visual/motion + non-evil global)
;;   scratch-leader-non-normal-key -- default "M-SPC" (insert / emacs states)
;;
;; Adding bindings in your own config (use the `map!' macro):
;;
;;   (map! :leader
;;     "p p" '(project-switch-project :which-key "switch project")
;;     "p f" '(project-find-file      :which-key "find file in project"))
;;
;; `map!' also handles non-leader cases:
;;
;;   (map! :map org-mode-map "C-c C-c" #'org-edit-special)
;;   (map! :mode python :states '(normal) "<tab>" #'python-indent-line)
;;
;; Or pass through any `general-define-key' arg verbatim. The function
;; form `scratch-leader-def' is still around for users who prefer it.

(defvar scratch-leader-key "SPC"
  "Leader prefix in normal / visual / motion evil states.
Also used as the global prefix when evil isn't loaded.
Override BEFORE calling `scratch!'.")

(defvar scratch-leader-non-normal-key "M-SPC"
  "Leader prefix in insert / emacs evil states.
Override BEFORE calling `scratch!'.")

;; which-key: pop up available bindings after a short pause.
(use-package which-key
  :demand t
  :init
  (setq which-key-idle-delay 0.3
        which-key-popup-type 'side-window
        which-key-side-window-location 'bottom
        which-key-side-window-max-height 0.4)
  :config
  (which-key-mode 1))

;; general.el: declarative key binding system.
(use-package general
  :demand t
  :config
  ;; `override' forces these bindings to win over major-mode and
  ;; minor-mode keymaps, which is what you want for a leader.
  (general-override-mode 1)
  ;; Make `general-override-mode-map' an evil *intercept* map for the
  ;; relevant states so SPC wins over `evil-motion-state-map' bindings
  ;; like `evil-forward-char' (active in *Messages*, magit, etc.).
  ;; The :set on `general-override-states' would do this normally, but
  ;; only when set via customize -- not on package load.
  (general-override-make-intercept-maps
   nil '(insert emacs hybrid normal visual motion operator replace))

  (general-create-definer scratch-leader-def
    :states '(normal visual motion emacs insert)
    :keymaps 'override
    :prefix scratch-leader-key
    :non-normal-prefix scratch-leader-non-normal-key)

  ;; Doom-style `map!' macro -- a thin wrapper over `general-define-key'
  ;; with `:leader' / `:map' / `:mode' shortcuts. See the docstring for
  ;; usage. Bind keys anywhere with one consistent surface.
  (defmacro map! (&rest args)
    "Bind keys with scratch's ergonomics, on top of `general-define-key'.

Recognized keywords (others pass through):
  :leader      bind under the leader prefix (uses `scratch-leader-key' and
               `scratch-leader-non-normal-key'). Implies a sensible default
               set of evil states.
  :map MAP     bind in keymap MAP (alias for general's `:keymaps MAP').
  :mode MODE   bind in MODE-map (shorthand: `:mode org' -> `:keymaps org-mode-map').

Anything else (`:states', `:prefix', `:after', ...) is forwarded as-is
to `general-define-key'.

Examples:
  (map! :leader \"f f\" #'find-file
                \"f s\" #'save-buffer)
  (map! :map org-mode-map \"C-c C-c\" #'org-edit-special)
  (map! :mode python :states \\='normal \"<tab>\" #'python-indent-line)"
    (let ((leader-p nil)
          (out nil))
      (while args
        (pcase (car args)
          (:leader
           (setq leader-p t)
           (setq args (cdr args)))
          (:map
           (push :keymaps out)
           (push `(quote ,(cadr args)) out)
           (setq args (cddr args)))
          (:mode
           (push :keymaps out)
           (push `(quote ,(intern (format "%s-mode-map" (cadr args)))) out)
           (setq args (cddr args)))
          ((pred keywordp)
           (push (car args) out)
           (push (cadr args) out)
           (setq args (cddr args)))
          (_
           (push (car args) out)
           (setq args (cdr args)))))
      (setq out (nreverse out))
      (when leader-p
        (setq out (append (list :states ''(normal visual motion emacs insert)
                                :keymaps ''override
                                :prefix 'scratch-leader-key
                                :non-normal-prefix 'scratch-leader-non-normal-key)
                          out)))
      `(general-define-key ,@out)))

  ;; Doom-flavored starter vocabulary. Override or extend in your config.
  (map! :leader
    "SPC" '(execute-extended-command       :which-key "M-x")
    ":"   '(execute-extended-command       :which-key "M-x")
    "."   '(find-file                      :which-key "find file")
    ","   '(switch-to-buffer               :which-key "switch buffer")
    "TAB" '(scratch/switch-to-last-buffer  :which-key "last buffer")

    "f"   '(:ignore t                :which-key "file")
    "f f" '(find-file                :which-key "find file")
    "f s" '(save-buffer              :which-key "save buffer")
    "f S" '(save-some-buffers        :which-key "save all")
    "f r" '(recentf                  :which-key "recent files")

    "b"   '(:ignore t                          :which-key "buffer")
    "b b" '(switch-to-buffer                   :which-key "switch buffer")
    "b ]" '(next-buffer                        :which-key "next buffer")
    "b [" '(previous-buffer                    :which-key "previous buffer")
    "b n" '(next-buffer                        :which-key "next buffer")
    "b p" '(previous-buffer                    :which-key "previous buffer")
    "b c" '(clone-indirect-buffer              :which-key "clone buffer")
    "b C" '(clone-indirect-buffer-other-window :which-key "clone in other window")
    "b d" '(kill-current-buffer                :which-key "kill buffer")
    "b k" '(kill-current-buffer                :which-key "kill buffer")
    "b K" '(scratch/kill-all-buffers           :which-key "kill all buffers")
    "b O" '(scratch/kill-other-buffers         :which-key "kill other buffers")
    "b i" '(ibuffer                            :which-key "ibuffer")
    "b r" '(revert-buffer                      :which-key "revert buffer")
    "b R" '(rename-buffer                      :which-key "rename buffer")
    "b s" '(save-buffer                        :which-key "save buffer")
    "b S" '(save-some-buffers                  :which-key "save all buffers")
    "b l" '(scratch/switch-to-last-buffer      :which-key "last buffer")
    "b x" '(scratch/scratch-buffer             :which-key "*scratch*")
    "b N" '(scratch/new-empty-buffer           :which-key "new empty buffer")
    "b e" '(erase-buffer                       :which-key "erase buffer")
    "b Y" '(scratch/copy-buffer-filepath       :which-key "copy filepath:line")
    "b P" '(scratch/replace-buffer-from-clipboard :which-key "paste over buffer")

    "w"   '(:ignore t                :which-key "window")
    "w h" '(windmove-left            :which-key "left")
    "w j" '(windmove-down            :which-key "down")
    "w k" '(windmove-up              :which-key "up")
    "w l" '(windmove-right           :which-key "right")
    "w s" '(split-window-below       :which-key "split below")
    "w v" '(split-window-right       :which-key "split right")
    "w d" '(delete-window            :which-key "delete window")
    "w D" '(delete-other-windows     :which-key "delete others")

    "h"   '(:ignore t                :which-key "help")
    "h f" '(describe-function        :which-key "describe function")
    "h v" '(describe-variable        :which-key "describe variable")
    "h k" '(describe-key             :which-key "describe key")
    "h m" '(describe-mode            :which-key "describe mode")

    "q"   '(:ignore t                :which-key "quit")
    "q q" '(save-buffers-kill-terminal :which-key "quit Emacs")
    "q r" '(restart-emacs            :which-key "restart Emacs"))

  ;; If the version-control module is on, surface magit-status under SPC g.
  (when (modulep! :emacs vc)
    (map! :leader
      "g"   '(:ignore t      :which-key "git")
      "g g" '(magit-status   :which-key "magit status")
      "g d" '(magit-dispatch :which-key "magit dispatch")))

  ;; Project menu, backed by built-in project.el.
  (map! :leader
    "p"   '(:ignore t                   :which-key "project")
    "p p" '(project-switch-project      :which-key "switch project")
    "p l" '(scratch/list-projects       :which-key "list projects")
    "p f" '(project-find-file           :which-key "find file")
    "p b" '(project-switch-to-buffer    :which-key "switch buffer")
    "p k" '(project-kill-buffers        :which-key "kill buffers")
    "p s" '(project-find-regexp         :which-key "search (regexp)")
    "p !" '(project-shell-command       :which-key "shell command")
    "p d" '(project-dired               :which-key "dired")
    "p F" '(project-forget-project      :which-key "forget project"))

  ;; Consult enrichments when the vertico/consult bundle is enabled.
  ;; consult-* commands are autoloaded by straight, so binding them here
  ;; works even though :completion vertico's config.el may have run first.
  (when (modulep! :completion vertico)
    (map! :leader
      "b b" '(consult-buffer            :which-key "switch buffer")
      "f r" '(consult-recent-file       :which-key "recent files")
      "y"   '(consult-yank-pop          :which-key "yank ring")

      "s"   '(:ignore t                 :which-key "search")
      "s s" '(consult-line              :which-key "search buffer")
      "s i" '(consult-imenu             :which-key "imenu")
      "s p" '(consult-ripgrep           :which-key "search project (rg)")
      "s f" '(consult-find              :which-key "find file (project)")

      "p b" '(consult-project-buffer    :which-key "project buffers"))))

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

;; Buffer helper commands (scratch/switch-to-last-buffer, scratch/scratch-buffer,
;; scratch/copy-buffer-filepath, etc.) live in `lisp/scratch-buffer.el', loaded
;; by the framework's init.el via `(require 'scratch-buffer)'.
