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

;; Emacs 32 turned face inheritance cycles into hard errors, and
;; doom-themes trips one against gnus's own defaults: its
;; `gnus-group-news-low-empty' spec inherits `gnus-group-news-low', while
;; gnus's defface makes `gnus-group-news-low' inherit
;; `gnus-group-news-low-empty'. The cycle fires wherever the second spec
;; lands (theme load if gnus is already up, gnus load if a theme is
;; already enabled), so doom-themes' definition-order fix (upstream
;; 53645a9) can't help. Tolerate exactly this class of cycle for
;; gnus-group-* faces: the offending :inherit is skipped and the face
;; falls back to gnus's default styling, instead of aborting the whole
;; theme load or gnus's load.
(when (>= emacs-major-version 32)
  (define-advice internal-set-lisp-face-attribute
      (:around (orig face attr value &optional frame)
               scratch-theme-tolerate-gnus-face-cycles)
    (if (and (eq attr :inherit)
             (string-prefix-p "gnus-group-" (symbol-name face)))
        (condition-case err
            (funcall orig face attr value frame)
          (error
           (unless (string-prefix-p
                    "Face inheritance results in inheritance cycle"
                    (error-message-string err))
             (signal (car err) (cdr err)))))
      (funcall orig face attr value frame))))

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
    ;; Trust both themes upfront so `load-theme' (used by auto-dark
    ;; on appearance change) doesn't prompt for the custom-safe-themes
    ;; confirmation, which silently no-ops when there's no UI to
    ;; answer it (daemon, --batch, etc.).
    (setq custom-safe-themes t)
    ;; `customize-set-variable' triggers the defcustom :set lambda
    ;; for `auto-dark-themes', which pre-`load-theme's both themes
    ;; up-front. This (a) silences the safe-themes prompt at switch
    ;; time and (b) lets auto-dark use the fast `enable-theme'
    ;; path on subsequent flips. Plain `setq' bypasses the :set form.
    (customize-set-variable 'auto-dark-themes
                            (list (list scratch-theme-dark)
                                  (list scratch-theme-light)))
    ;; In batch sessions (sync, scripts) there's no GUI to query for the
    ;; OS appearance; skip auto-dark there and load the dark default so
    ;; sync output stays quiet.
    (cond
     (noninteractive
      (load-theme scratch-theme-dark t))
     ((daemonp)
      ;; A headless daemon has no GUI frame at init, so `window-system'
      ;; is nil and auto-dark cannot detect the OS appearance (its
      ;; applescript mechanism requires a graphic display). Enable it
      ;; on the first client frame instead; the `unless' keeps the
      ;; hook idempotent across reconnects and re-evals.
      (add-hook 'server-after-make-frame-hook
                (lambda ()
                  (unless auto-dark-mode
                    (auto-dark-mode 1)))))
     (t
      ;; Pass `1' explicitly: a bare `(auto-dark-mode)' toggles, and
      ;; if anything else already activated the mode (re-eval, custom
      ;; file replay) the toggle would turn it OFF.
      (auto-dark-mode 1))))))
