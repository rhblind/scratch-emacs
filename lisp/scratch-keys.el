;;; scratch-keys.el --- key-binding macros -*- lexical-binding: t; -*-
;;
;; Framework-level installation of `general' and the `map!' macro. Exposing
;; these at framework level lets every module call `(map! :leader ...)' or
;; `(map! :map foo-map ...)' regardless of module load order.
;;
;; The :editor leader module, when enabled, sets up the leader-specific
;; defvars (`scratch-leader-key' etc.), enables `general-override-mode',
;; and turns the override map into an evil intercept map -- without it,
;; `:leader' / `:localleader' bindings still install but won't fire.

(straight-use-package 'general)
(require 'general)

;;; Leader / localleader prefix variables.
;;
;; Defined at framework level (rather than in the :editor leader module)
;; so the `map!' expansions referencing these symbols resolve regardless
;; of which order modules load in. The leader module enables the override
;; mode, intercept maps, and which-key -- without it, leader bindings
;; install but won't fire interactively.

(defvar scratch-leader-key "SPC"
  "Leader prefix in normal / visual / motion evil states.
Also used as the global prefix when evil isn't loaded.
Override BEFORE calling `scratch!'.")

(defvar scratch-leader-non-normal-key "M-SPC"
  "Leader prefix in insert / emacs evil states.
Override BEFORE calling `scratch!'.")

(defvar scratch-localleader-key "SPC m"
  "Localleader prefix under the main leader, e.g. `SPC m n' for smerge-next.
Override BEFORE calling `scratch!'.")

(defvar scratch-localleader-alt-key ","
  "Direct localleader prefix in normal state, e.g. `,n' for smerge-next.
Only active in keymaps where `map!' has bound something under `:localleader'.
Override BEFORE calling `scratch!'.")

(defvar scratch-localleader-non-normal-key "M-SPC m"
  "Localleader prefix in insert / emacs evil states.
Override BEFORE calling `scratch!'.")

(defmacro map! (&rest args)
  "Bind keys with scratch's ergonomics, on top of `general-define-key'.

Recognized keywords (others pass through):
  :leader        bind under the leader prefix (uses `scratch-leader-key' and
                 `scratch-leader-non-normal-key'). Implies a sensible default
                 set of evil states.
  :localleader   bind under the localleader prefix. Generates two binding
                 sets so both `SPC m KEY' (under main leader) and `, KEY'
                 (direct in normal state) work. Combine with `:map MAP' to
                 scope to a major-mode keymap (recommended).
  :map MAP       bind in keymap MAP (alias for general's `:keymaps MAP').
  :mode MODE     bind in MODE-map (shorthand: `:mode org' -> `:keymaps org-mode-map').

Anything else (`:states', `:prefix', `:after', ...) is forwarded as-is
to `general-define-key'.

Examples:
  (map! :leader \"f f\" #'find-file
                \"f s\" #'save-buffer)
  (map! :map org-mode-map \"C-c C-c\" #'org-edit-special)
  (map! :map smerge-mode-map :localleader
        \"n\" #'smerge-next
        \"p\" #'smerge-prev)
  (map! :mode python :states \\='normal \"<tab>\" #'python-indent-line)"
  (let ((leader-p nil)
        (localleader-p nil)
        (out nil))
    (while args
      (pcase (car args)
        (:leader
         (setq leader-p t)
         (setq args (cdr args)))
        (:localleader
         (setq localleader-p t)
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
    (cond
     (leader-p
      `(general-define-key
        :states ',(quote (normal visual motion emacs insert))
        :keymaps 'override
        :prefix scratch-leader-key
        :non-normal-prefix scratch-leader-non-normal-key
        ,@out))
     (localleader-p
      ;; Two binding passes: one under SPC m (main-leader-relative) and
      ;; one under `,' (direct in normal/visual state). Both target the
      ;; same keymap(s) the user supplied via :map / :mode.
      `(progn
         (general-define-key
          :states ',(quote (normal visual motion emacs insert))
          :prefix scratch-localleader-key
          :non-normal-prefix scratch-localleader-non-normal-key
          ,@out)
         (general-define-key
          :states ',(quote (normal visual))
          :prefix scratch-localleader-alt-key
          ,@out)))
     (t
      `(general-define-key ,@out)))))

(provide 'scratch-keys)
;;; scratch-keys.el ends here
