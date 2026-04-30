;;; modules/ui/theme/config.el -*- lexical-binding: t; -*-
;;
;; Theme: ships rougier's nano-theme as the default
;; (https://github.com/rougier/nano-theme). By default the module follows
;; the OS appearance via the auto-dark package (cross-platform: macOS /
;; Linux / Windows / Android via Termux); pass +light or +dark to force a
;; static choice.
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

(defvar scratch-theme-dark 'nano-dark
  "Theme symbol loaded as the dark theme.
Used with +dark, and as the dark variant for the default +auto behavior.
Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-theme-light 'nano-light
  "Theme symbol loaded as the light theme.
Used with +light, and as the light variant for the default +auto behavior.
Override by `setq' BEFORE calling `scratch!'.")

;; nano-theme is the bundled default; always make it available.
(use-package nano-theme :demand t)

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
    (auto-dark-mode))))
