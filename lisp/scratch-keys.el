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

(defvar scratch-localleader-key ","
  "Localleader prefix in evil normal / visual / motion states.
For example `,n' for smerge-next when point is on a conflict marker.
Override BEFORE calling `scratch!'.")

(defvar scratch-localleader-non-normal-key "M-,"
  "Localleader prefix in evil insert / emacs states.
A separate key is needed because typing `,' in insert mode would
otherwise insert a comma. Override BEFORE calling `scratch!'.")

(defun scratch-keys--with-desc (def desc)
  "Return a binding form that combines DEF with `:which-key' DESC.
Handles the common DEF shapes: bare symbol, `'sym', `#'sym', a
quoted list `'(sym ...)', and lambda / arbitrary forms.  general.el
extracts `:which-key' from list definitions whose car is a valid
command, so wrapping a lambda in `(quote (LAMBDA :which-key DESC))'
gives which-key a label while preserving the binding."
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
   ;; bare symbol -- evaluate at runtime so keymaps resolve to their
   ;; value (general needs a keymap value, not the symbol, to create
   ;; a prefix binding via define-key).
   ((symbolp def)
    `(list (scratch-keys--resolve-binding ',def) :which-key ,desc))
   ;; lambda or other form: wrap in a list with :which-key so general
   ;; can extract the description while still binding the command.
   (t `(quote (,def :which-key ,desc)))))

(defun scratch-keys--resolve-binding (sym)
  "Resolve SYM for `define-key': return the keymap value when SYM is
a keymap variable, otherwise the symbol itself (command binding)."
  (let ((val (and (boundp sym) (symbol-value sym))))
    (if (keymapp val)
        val
      sym)))

(defun scratch-keys--prefixed (prefix key)
  "Return KEY prefixed by PREFIX (with a separating space)."
  (let ((kstr (if (stringp key) key (key-description key))))
    (if prefix (concat prefix " " kstr) kstr)))

(defconst scratch-keys--state-chars
  '((?n . normal)
    (?v . visual)
    (?i . insert)
    (?e . emacs)
    (?o . operator)
    (?m . motion)
    (?r . replace)
    (?g . global))
  "Letter -> evil-state map for `map!' state-shorthand keywords.
`:n' -> (normal); `:nv' -> (normal visual); `:nvm' -> (normal visual motion).")

(defun scratch-keys--state-keyword-p (kw)
  "Non-nil if KW is a state-shorthand keyword like `:n', `:nv', `:nvm'.
A keyword qualifies when its name is one or more characters that all
appear as keys in `scratch-keys--state-chars'."
  (and (keywordp kw)
       (let ((name (substring (symbol-name kw) 1)))
         (and (> (length name) 0)
              (cl-every (lambda (c) (assq c scratch-keys--state-chars))
                        (string-to-list name))))))

(defun scratch-keys--keyword-to-states (kw)
  "Convert a state-shorthand keyword (e.g. `:nv') to a list of states."
  (cl-loop for c across (substring (symbol-name kw) 1)
           collect (cdr (assq c scratch-keys--state-chars))))

(defun scratch-keys--expand-body (body &optional prefix)
  "Walk BODY -- the binding part of a `map!' call -- into a cons
\(DEFAULT . SCOPED) for splicing into `general-define-key' calls:

  DEFAULT  -- flat (KEY DEF KEY DEF ...) sequence with no per-binding
              state restriction. Goes into the main general-define-key.
  SCOPED   -- alist of ((STATES . (KEY DEF ...)) ...) for bindings that
              were tagged with a state-shorthand keyword (`:n', `:nv',
              ...). Each entry needs its own general-define-key with
              :states bound to STATES.

Handles `:desc', state shorthands (Doom-style: `:n', `:i', `:nv', ...),
and recursive `:prefix-map' / `:prefix' groupings.

PREFIX is the accumulated prefix from enclosing `:prefix' / `:prefix-map'
forms (a string), prepended to every KEY here."
  (let ((default nil)
        (scoped nil)
        (pending-desc nil)
        (pending-states nil))
    (cl-labels
        ((emit (key def states)
           (cond
            (states
             (let ((cell (assoc states scoped)))
               (if cell
                   (setcdr cell (append (cdr cell) (list key def)))
                 (push (cons states (list key def)) scoped))))
            (t
             (push key default)
             (push def default))))
         (merge-sub (sub)
           ;; SUB is the cons returned by a recursive call.
           ;; Append its default to ours (preserving order), and merge
           ;; its scoped groups into ours.
           (dolist (item (car sub))
             (push item default))
           (dolist (g (cdr sub))
             (let ((cell (assoc (car g) scoped)))
               (if cell
                   (setcdr cell (append (cdr cell) (cl-copy-list (cdr g))))
                 (push (cons (car g) (cl-copy-list (cdr g))) scoped))))))
      (while body
        (pcase (car body)
          (:desc
           (setq pending-desc (cadr body))
           (setq body (cddr body)))
          ;; State shorthand (:n, :nv, :nvm, ...) -- one-shot, applied to
          ;; the next KEY/DEF pair (or the next prefix-map's children).
          ((and (pred keywordp)
                (pred scratch-keys--state-keyword-p))
           (setq pending-states
                 (scratch-keys--keyword-to-states (car body)))
           (setq body (cdr body)))
          ;; (:prefix-map SPEC BODY...) and (:prefix SPEC BODY...)
          ((or `(:prefix-map ,spec . ,inner)
               `(:prefix     ,spec . ,inner))
           (let* ((p-key (scratch-keys--prefixed
                          prefix
                          (if (consp spec) (car spec) spec)))
                  (label (and (consp spec) (cdr spec)))
                  (sub (scratch-keys--expand-body inner p-key)))
             (when label
               ;; Label binding: which-key annotation for the prefix
               ;; itself. Goes into whatever scope the prefix was tagged
               ;; with (defaults to no state, i.e. the default group).
               (emit p-key
                     `(quote (:ignore t :which-key ,label))
                     pending-states))
             (cond
              (pending-states
               ;; Re-route the recursive call's default group into our
               ;; pending-states scope. Scoped groups from inside come
               ;; through unchanged (an inner :n on top of an outer :v
               ;; respects the inner).
               (let ((sub-default (car sub)))
                 (cl-loop while sub-default
                          for k = (pop sub-default)
                          for d = (pop sub-default)
                          do (emit k d pending-states)))
               (dolist (g (cdr sub))
                 (let ((cell (assoc (car g) scoped)))
                   (if cell
                       (setcdr cell
                               (append (cdr cell) (cl-copy-list (cdr g))))
                     (push (cons (car g) (cl-copy-list (cdr g)))
                           scoped)))))
              (t (merge-sub sub)))
             (setq pending-states nil)
             (setq body (cdr body))))
          ;; KEY/DEF pair.
          ((or (pred stringp) (pred vectorp))
           (let* ((key (scratch-keys--prefixed prefix (car body)))
                  (def (if pending-desc
                           (scratch-keys--with-desc (cadr body) pending-desc)
                         (cadr body))))
             (emit key def pending-states))
           (setq pending-desc nil
                 pending-states nil
                 body (cddr body)))
          ((pred keywordp)
           ;; Unrecognized keyword -- pass through to the default group.
           (push (car body) default)
           (push (cadr body) default)
           (setq body (cddr body)))
          (_
           (push (car body) default)
           (setq body (cdr body))))))
    (cons (nreverse default) (nreverse scoped))))

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
  :n / :i / :v / :m / :o / :e /    state shorthand (Doom-style): apply ONLY to
  :r / :g (and combos like :nv,    the next KEY/DEF pair (or the next
  :nvm)                            (:prefix-map ...) group). Each character
                                   maps to an evil state via
                                   `scratch-keys--state-chars'.
  (:prefix-map (KEY . LABEL) ...)  group bindings under KEY with a which-key
                                   label (like Doom's `:prefix-map').
  (:prefix KEY LABEL ...)          alternative spelling of the above.
  Both `:prefix-map' and `:prefix' nest.

Anything else (`:states', `:prefix' as a top-level kw, `:after', ...) is
forwarded as-is to `general-define-key'. State shorthands aren't allowed
under `:leader' / `:localleader' (those forms pin their own `:states').

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
    ;; belong to the body, as do state-shorthand keywords (`:n', `:nv',
    ;; ...) -- their handling lives in `scratch-keys--expand-body'.
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
        ((and (pred keywordp) kw
              (guard (or (memq kw body-keywords)
                         (scratch-keys--state-keyword-p kw))))
         ;; Body keyword -- consume one item (the keyword) and let pass 2
         ;; handle it together with the following key/def pair.
         (push (car args) body)
         (setq args (cdr args)))
        ((and (pred keywordp))
         ;; Top-level pass-through kw (consumes value).
         (push (car args) top-level)
         (push (cadr args) top-level)
         (setq args (cddr args)))
        (_
         (push (car args) body)
         (setq args (cdr args)))))
    (setq top-level (nreverse top-level)
          body      (nreverse body))
    ;; Pass 2: expand the body into (DEFAULT . SCOPED) and assemble
    ;; one or more general-define-key forms. State shorthands inside
    ;; :leader / :localleader bodies aren't supported -- the leader
    ;; already pins its own :states.
    (let* ((expanded (scratch-keys--expand-body body))
           (default  (car expanded))
           (scoped   (cdr expanded)))
      (cond
       (leader-p
        (when scoped
          (error "map!: state shorthand (e.g. :n) is not supported under :leader"))
        `(general-define-key
          :states ',(quote (normal visual motion emacs insert))
          :keymaps 'override
          :prefix scratch-leader-key
          :non-normal-prefix scratch-leader-non-normal-key
          ,@top-level
          ,@default))
       (localleader-p
        (when scoped
          (error "map!: state shorthand (e.g. :n) is not supported under :localleader"))
        ;; Single general-define-key with `:prefix' (normal/visual/motion)
        ;; and `:non-normal-prefix' (insert/emacs); mirrors Doom's
        ;; `define-localleader-key!'.
        `(general-define-key
          :states ',(quote (normal visual motion emacs insert))
          :prefix scratch-localleader-key
          :non-normal-prefix scratch-localleader-non-normal-key
          ,@top-level
          ,@default))
       (t
        (let ((forms nil))
          (when default
            (push `(general-define-key ,@top-level ,@default) forms))
          (dolist (g scoped)
            (push `(general-define-key
                    :states ',(car g)
                    ,@top-level
                    ,@(cdr g))
                  forms))
          (cond
           ((null forms) nil)
           ((null (cdr forms)) (car forms))
           (t `(progn ,@(nreverse forms))))))))))

(provide 'scratch-keys)
;;; scratch-keys.el ends here
