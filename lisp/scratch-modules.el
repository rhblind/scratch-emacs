;;; scratch-modules.el --- module system for the scratch framework -*- lexical-binding: t; -*-
;;
;; Provides `scratch!' (declare + load modules) and `modulep!' (predicate).
;; Modules are directories containing optional `packages.el' and `config.el'
;; files. They're discovered in two roots, user-dir taking priority on a
;; name collision:
;;
;;   $SCRATCHDIR/modules/<category>/<name>/
;;   $EMACSDIR/modules/<category>/<name>/
;;
;; A module spec is either a bare symbol or a list of (NAME +FLAG ...).
;; Flags are symbols starting with `+'. Example:
;;
;;   (scratch! :tools magit docker
;;             :lang (python +lsp) (rust +lsp))
;;
;; Inside a module's config.el you can branch on flags:
;;
;;   (when (modulep! +lsp) (use-package lsp-mode :defer t))
;;
;; Or check whether another module is enabled:
;;
;;   (when (modulep! :tools magit) (...))

(require 'cl-lib)

(defvar scratch-modules nil
  "Active modules as a list of (CATEGORY NAME FLAGS) entries.")

(defvar scratch--current-module nil
  "Bound by the loader to the module entry currently being loaded.
`modulep!' uses this for bare `+flag' checks.")

(defun scratch--module-entry (category name)
  "Return the entry for CATEGORY/NAME in `scratch-modules', or nil."
  (cl-find-if (lambda (m) (and (eq (car m) category) (eq (cadr m) name)))
              scratch-modules))

(defun scratch--parse-spec (spec)
  "Parse a flat SPEC list from `scratch!' into module entries."
  (let (current-category modules)
    (dolist (item spec)
      (cond
       ((keywordp item)
        (setq current-category item))
       ((null current-category)
        (error "scratch!: module %S given before any :category keyword" item))
       ((symbolp item)
        (push (list current-category item nil) modules))
       ((consp item)
        (let* ((name (car item))
               (flags (cl-remove-if-not
                       (lambda (s)
                         (and (symbolp s)
                              (let ((n (symbol-name s)))
                                (and (> (length n) 1) (eq (aref n 0) ?+)))))
                       (cdr item))))
          (unless (symbolp name)
            (error "scratch!: module name must be a symbol, got %S" name))
          (push (list current-category name flags) modules)))
       (t (error "scratch!: invalid spec item: %S" item))))
    (nreverse modules)))

(defun scratch--module-dir (category name)
  "Return the directory holding the CATEGORY/NAME module, or nil."
  (let* ((rel (format "modules/%s/%s/"
                      (substring (symbol-name category) 1)
                      name))
         (candidates (list (expand-file-name rel scratch-user-dir)
                           (expand-file-name rel scratch-emacs-dir))))
    (cl-find-if #'file-directory-p candidates)))

(defun scratch--load-module-file (entry filename)
  "Load FILENAME from the module described by ENTRY, if present."
  (let* ((category (car entry))
         (name (cadr entry))
         (dir (scratch--module-dir category name)))
    (cond
     ((null dir)
      (message "[scratch] module not found: %s %s" category name))
     (t
      (let ((path (expand-file-name filename dir))
            (scratch--current-module entry))
        (when (file-exists-p path)
          (load path nil 'nomessage)))))))

(defun scratch--load-modules (modules)
  "Load packages.el of every MODULES entry, then config.el of every entry."
  (dolist (m modules) (scratch--load-module-file m "packages.el"))
  (dolist (m modules) (scratch--load-module-file m "config.el")))

(defmacro scratch! (&rest spec)
  "Enable and load modules described by SPEC.
SPEC is a sequence of :category keywords and module specs. Each module
spec is either a NAME symbol or (NAME +FLAG ...). Modules' `packages.el'
files are loaded first (all of them), then their `config.el' files."
  (declare (indent defun))
  `(let ((mods (scratch--parse-spec ',spec)))
     (setq scratch-modules (append scratch-modules mods))
     (scratch--load-modules mods)))

(defmacro modulep! (&rest spec)
  "Predicate macro for module / flag presence.

Forms:
  (modulep! +FLAG)                   -- current module has +FLAG
  (modulep! :category name)          -- module is enabled
  (modulep! :category name +flag)    -- module is enabled with +flag"
  (cond
   ((and (= 1 (length spec))
         (symbolp (car spec))
         (let ((n (symbol-name (car spec))))
           (and (> (length n) 1) (eq (aref n 0) ?+))))
    `(memq ',(car spec) (nth 2 scratch--current-module)))
   ((and (= 2 (length spec))
         (keywordp (car spec))
         (symbolp (cadr spec)))
    `(and (scratch--module-entry ',(car spec) ',(cadr spec)) t))
   ((and (= 3 (length spec))
         (keywordp (car spec))
         (symbolp (cadr spec))
         (symbolp (caddr spec)))
    `(let ((m (scratch--module-entry ',(car spec) ',(cadr spec))))
       (and m (memq ',(caddr spec) (nth 2 m)) t)))
   (t (error "modulep!: invalid spec: %S" spec))))

(provide 'scratch-modules)
;;; modules.el ends here
