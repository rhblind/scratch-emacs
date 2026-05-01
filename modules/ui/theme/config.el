;;; modules/ui/theme/config.el -*- lexical-binding: t; -*-
;;
;; Theme: ships modus-operandi / modus-vivendi as the default stack.
;; Both are built-in to Emacs 28+ (Protesilaos Stavrou's high-contrast,
;; carefully tuned themes; pair cleanly with doom-modeline).
;;
;; By default the module follows the OS appearance via the auto-dark
;; package (cross-platform: macOS / Linux / Windows / Android via Termux);
;; pass +light or +dark to force a static choice.
;;
;; Flags:
;;   (none) / +auto -- follow the OS light/dark setting (the default).
;;   +light         -- always load `scratch-theme-light'.
;;   +dark          -- always load `scratch-theme-dark'.
;;
;; Overriding the themes:
;;   The dark / light theme symbols come from `scratch-theme-dark' /
;;   `scratch-theme-light'. To use something else, install the package and
;;   `setq' the vars BEFORE calling `scratch!', e.g. in your packages.el:
;;
;;     (straight-use-package 'doom-themes)
;;     (setq scratch-theme-dark  'doom-one
;;           scratch-theme-light 'doom-one-light)
;;     (scratch! :ui theme)        ; auto-follow OS, with doom themes

(defvar scratch-theme-dark 'modus-vivendi
  "Theme symbol loaded as the dark theme.
Used with +dark, and as the dark variant for the default +auto behavior.
Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-theme-light 'modus-operandi
  "Theme symbol loaded as the light theme.
Used with +light, and as the light variant for the default +auto behavior.
Override by `setq' BEFORE calling `scratch!'.")

;; Disable any currently-enabled themes before loading a new one. By
;; default `load-theme' stacks (additively layers) themes, which causes
;; face-color leakage from the previous theme into the new one --
;; symptoms include "modeline didn't follow the theme" or random faces
;; staying in the old palette. This advice gives us "one theme at a time"
;; semantics, matching what users typically expect.
(defun scratch-theme--disable-previous-a (theme &rest _)
  "Disable all currently-enabled themes other than THEME."
  (mapc (lambda (other)
          (unless (eq other theme)
            (disable-theme other)))
        custom-enabled-themes))
(advice-add 'load-theme :before #'scratch-theme--disable-previous-a)

(cond
 ((modulep! +light)
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme scratch-theme-light t))
 ((modulep! +dark)
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme scratch-theme-dark t))
 (t
  ;; Default: follow the OS. Also covers explicit +auto.
  (use-package auto-dark
    :demand t
    :config
    (setq auto-dark-themes (list (list scratch-theme-dark)
                                 (list scratch-theme-light)))
    ;; In batch sessions (sync, scripts) there's no GUI to query for the
    ;; OS appearance; skip auto-dark there and load the dark default so
    ;; sync output stays quiet.
    (if noninteractive
        (load-theme scratch-theme-dark t)
      (auto-dark-mode)))))
