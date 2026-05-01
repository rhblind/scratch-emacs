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

(defun scratch-keys--with-desc (def desc)
  "Return a binding form that combines DEF with `:which-key' DESC.
Handles the common DEF shapes: bare symbol, `'sym', `#'sym', and a
quoted list `'(sym ...)' (preserving any other plist entries)."
  (cond
   ;; #'sym
   ((and (consp def) (eq (car def) 'function))
    `(quote (,(cadr def) :which-key ,desc)))
   ;; 'sym (quoted symbol)
   ((and (consp def) (eq (car def) 'quote) (symbolp (cadr def)))
    `(quote (,(cadr def) :which-key ,desc)))
   ;; '(sym ...) -- quoted list; merge, replacing any existing :which-key.
   ((and (consp def) (eq (car def) 'quote) (consp (cadr def)))
    (let* ((inner (cadr def))
           (sym (car inner))
           (kept (cl-loop for cell on (cdr inner) by #'cddr
                          unless (memq (car cell) '(:which-key :wk))
                          collect (car cell) and collect (cadr cell))))
      `(quote (,sym ,@kept :which-key ,desc))))
   ;; bare symbol
   ((symbolp def)
    `(quote (,def :which-key ,desc)))
   ;; Anything else (lambda etc.): return unchanged.
   (t def)))

(defun scratch-keys--prefixed (prefix key)
  "Return KEY prefixed by PREFIX (with a separating space)."
  (let ((kstr (if (stringp key) key (key-description key))))
    (if prefix (concat prefix " " kstr) kstr)))

(defun scratch-keys--expand-body (body &optional prefix)
  "Walk BODY -- the binding part of a `map!' call -- into a flat
\(KEY DEF KEY DEF ...) sequence ready to splice into a
`general-define-key' call. Handles `:desc' and recursive
`:prefix-map' / `:prefix' groupings.

PREFIX is the accumulated prefix from enclosing `:prefix' / `:prefix-map'
forms (a string), prepended to every KEY here."
  (let ((out nil)
        (pending-desc nil))
    (while body
      (pcase (car body)
        (:desc
         (setq pending-desc (cadr body))
         (setq body (cddr body)))
        ;; (:prefix-map SPEC BODY...) and (:prefix SPEC BODY...)
        ;; SPEC is either KEY (a string) or (KEY . LABEL) cons cell.
        ;; Behavior matches Doom's `:prefix-map' / `:prefix'.
        ((or `(:prefix-map ,spec . ,inner)
             `(:prefix     ,spec . ,inner))
         (let* ((p-key (scratch-keys--prefixed
                        prefix
                        (if (consp spec) (car spec) spec)))
                (label (and (consp spec) (cdr spec))))
           (when label
             (push p-key out)
             (push `(quote (:ignore t :which-key ,label)) out))
           (setq out (append (reverse (scratch-keys--expand-body inner p-key))
                             out))
           (setq body (cdr body))))
        ;; KEY/DEF pair -- prefix the KEY if we're inside a group, then
        ;; consume any pending :desc.
        ((or (pred stringp) (pred vectorp))
         (push (scratch-keys--prefixed prefix (car body)) out)
         (push (if pending-desc
                   (scratch-keys--with-desc (cadr body) pending-desc)
                 (cadr body))
               out)
         (setq pending-desc nil)
         (setq body (cddr body)))
        ((pred keywordp)
         ;; Stray top-level keyword inside a body -- pass through as-is.
         (push (car body) out)
         (push (cadr body) out)
         (setq body (cddr body)))
        (_
         (push (car body) out)
         (setq body (cdr body)))))
    (nreverse out)))

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

Inside the binding body these are also recognised:
  :desc DESC                       which-key label for the next KEY/DEF pair.
  (:prefix-map (KEY . LABEL) ...)  group bindings under KEY with a which-key
                                   label (like Doom's `:prefix-map').
  (:prefix KEY LABEL ...)          alternative spelling of the above.
  Both `:prefix-map' and `:prefix' nest.

Anything else (`:states', `:prefix' as a top-level kw, `:after', ...) is
forwarded as-is to `general-define-key'.

Examples:
  (map! :leader
        :desc \"find file\" \"f f\" #'find-file
        :desc \"save\"      \"f s\" #'save-buffer)

  (map! :leader
        (:prefix-map (\"b\" . \"buffer\")
         :desc \"switch buffer\" \"b\" #'consult-buffer
         :desc \"kill buffer\"   \"k\" #'kill-current-buffer))

  (map! :map smerge-mode-map :localleader
        :desc \"next conflict\" \"n\" #'smerge-next
        :desc \"prev conflict\" \"p\" #'smerge-prev)"
  (let ((leader-p nil)
        (localleader-p nil)
        (top-level nil)   ; pass-through keyword args for general-define-key
        (body nil)        ; bindings, :desc, :prefix-map / :prefix groups
        (body-keywords '(:desc :prefix-map :prefix)))
    ;; Pass 1: separate top-level keywords (`:keymaps', `:states', ...)
    ;; from binding-body content. `:desc', `:prefix-map' and `:prefix'
    ;; belong to the body.
    (while args
      (pcase (car args)
        (:leader
         (setq leader-p t)
         (setq args (cdr args)))
        (:localleader
         (setq localleader-p t)
         (setq args (cdr args)))
        (:map
         (push :keymaps top-level)
         (push `(quote ,(cadr args)) top-level)
         (setq args (cddr args)))
        (:mode
         (push :keymaps top-level)
         (push `(quote ,(intern (format "%s-mode-map" (cadr args)))) top-level)
         (setq args (cddr args)))
        ((and (pred keywordp) kw (guard (not (memq kw body-keywords))))
         ;; Top-level pass-through kw
         (push (car args) top-level)
         (push (cadr args) top-level)
         (setq args (cddr args)))
        (_
         (push (car args) body)
         (setq args (cdr args)))))
    (setq top-level (nreverse top-level)
          body      (nreverse body))
    ;; Pass 2: recursively expand the body into a flat key/def sequence.
    (let ((expanded (scratch-keys--expand-body body)))
      (cond
       (leader-p
        `(general-define-key
          :states ',(quote (normal visual motion emacs insert))
          :keymaps 'override
          :prefix scratch-leader-key
          :non-normal-prefix scratch-leader-non-normal-key
          ,@top-level
          ,@expanded))
       (localleader-p
        `(progn
           (general-define-key
            :states ',(quote (normal visual motion emacs insert))
            :prefix scratch-localleader-key
            :non-normal-prefix scratch-localleader-non-normal-key
            ,@top-level
            ,@expanded)
           (general-define-key
            :states ',(quote (normal visual))
            :prefix scratch-localleader-alt-key
            ,@top-level
            ,@expanded)))
       (t
        `(general-define-key ,@top-level ,@expanded))))))

(provide 'scratch-keys)
;;; scratch-keys.el ends here
