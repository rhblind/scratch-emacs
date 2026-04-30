;;; init.el --- scratch framework init -*- lexical-binding: t; -*-
;;
;; The framework lives in this directory: straight bootstrap, use-package
;; setup, and a few sane defaults. The user's actual configuration lives in
;; SCRATCHDIR (default ~/.scratch.d/) as a literate config.org that tangles
;; to config.el + packages.el; both get loaded after the framework's own
;; setup runs.

(require 'cl-lib)

(defvar scratch-emacs-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Path to the scratch framework dir (this repo).")

(defvar scratch-user-dir
  (file-name-as-directory
   (expand-file-name (or (getenv "SCRATCHDIR") "~/.scratch.d")))
  "Path to the user's config dir (analogue of DOOMDIR).")

;;; straight.el bootstrap (https://github.com/radian-software/straight.el)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;;; use-package, installed and used by default via straight
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;;; Module system. Provides `scratch!' / `modulep!' macros. Defines no
;;; modules itself; opt in by calling `scratch!' from your user config.
(load (expand-file-name "modules.el" scratch-emacs-dir) nil 'nomessage)

;;; Customize output stays under user-emacs-directory (i.e. this framework dir).
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

;;; Literate user config: tangle $SCRATCHDIR/config.org -> config.el +
;;; packages.el on demand, then load the tangled output.
(defun scratch--tangle-if-stale (org-file targets)
  "Re-tangle ORG-FILE when any path in TARGETS is missing or older than it."
  (when (and (file-exists-p org-file)
             (cl-some (lambda (target)
                        (or (not (file-exists-p target))
                            (file-newer-than-file-p org-file target)))
                      targets))
    (require 'org)
    (require 'ob-tangle)
    (let ((org-confirm-babel-evaluate nil)
          (gc-cons-threshold most-positive-fixnum))
      (message "[scratch] tangling %s..." (file-name-nondirectory org-file))
      (org-babel-tangle-file org-file))))

(let ((org      (expand-file-name "config.org"  scratch-user-dir))
      (config   (expand-file-name "config.el"   scratch-user-dir))
      (packages (expand-file-name "packages.el" scratch-user-dir)))
  (condition-case err
      (scratch--tangle-if-stale org (list config packages))
    (error (message "[scratch] tangle failed: %S" err)))
  (when (file-exists-p packages) (load packages nil 'nomessage))
  (when (file-exists-p config)   (load config   nil 'nomessage)))
