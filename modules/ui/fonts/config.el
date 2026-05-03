;;; modules/ui/fonts/config.el -*- lexical-binding: t; -*-
;;
;; Comfortable default font sizing + mixed-pitch in prose modes.
;; Emacs' built-in default is small on most modern HiDPI displays; 14pt
;; is a good compromise across screens. Families are left at system
;; defaults unless overridden.
;;
;; Overrides (set BEFORE calling `scratch!'):
;;   scratch-font-height           -- default 140 (= 14pt; units are 1/10 pt).
;;   scratch-font-family           -- default nil (system monospace).
;;   scratch-font-variable-family  -- default nil (system variable-pitch).
;;   scratch-mixed-pitch-modes     -- modes to auto-enable `mixed-pitch-mode' in.

(defvar scratch-font-height 140
  "Default font height in 1/10 pt (e.g. 140 = 14pt).
Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-font-family nil
  "Monospace font family (string), or nil to keep the system default.
Override by `setq' BEFORE calling `scratch!'.")

(defvar scratch-font-variable-family nil
  "Variable-pitch font family (string), or nil to keep the system default.
Override by `setq' BEFORE calling `scratch!'.")

(defun scratch-fonts--apply (&optional _frame)
  "Apply `scratch-font-*' settings to the default / fixed-pitch / variable-pitch faces."
  (let ((h scratch-font-height))
    (set-face-attribute 'default       nil :height h)
    (set-face-attribute 'fixed-pitch    nil :height h)
    (set-face-attribute 'variable-pitch nil :height h)
    (when scratch-font-family
      (set-face-attribute 'default    nil :family scratch-font-family)
      (set-face-attribute 'fixed-pitch nil :family scratch-font-family))
    (when scratch-font-variable-family
      (set-face-attribute 'variable-pitch nil :family scratch-font-variable-family))))

;; Apply now for direct GUI launches; defer to first frame for daemons
;; (faces aren't fully realised before the first frame exists).
(if (daemonp)
    (add-hook 'after-make-frame-functions #'scratch-fonts--apply)
  (scratch-fonts--apply))

;;;; Mixed-pitch -- variable-pitch in prose modes
;;
;; Mirrors the user's Doom setup: in prose-y modes the buffer's default
;; face becomes `variable-pitch'; code blocks, tables, line numbers,
;; and similar regions stay fixed-pitch via `mixed-pitch-fixed-pitch-faces'.

(defvar scratch-mixed-pitch-modes
  '(org-mode markdown-mode gfm-mode Info-mode
    help-mode apropos-mode
    Man-mode woman-mode)
  "Modes in which `mixed-pitch-mode' should auto-enable.
Covers prose modes (org / markdown), the help / describe-* family
(`SPC h f' / `h v' / `h m' / ...), and Unix man / woman pages.
Code samples, identifiers, and font-lock'd regions stay fixed-pitch
via `mixed-pitch-fixed-pitch-faces'.

Override by `setq' BEFORE calling `scratch!'. To disable mixed-pitch
entirely, `(setq scratch-mixed-pitch-modes nil)'.")

(use-package mixed-pitch
  :commands mixed-pitch-mode
  :init
  (defun scratch-fonts--init-mixed-pitch-h ()
    "Enable mixed-pitch in already-open buffers and add a hook to each
mode in `scratch-mixed-pitch-modes' so future buffers get it too."
    (when (memq major-mode scratch-mixed-pitch-modes)
      (mixed-pitch-mode 1))
    (dolist (mode scratch-mixed-pitch-modes)
      (add-hook (intern (format "%s-hook" mode)) #'mixed-pitch-mode)))
  ;; Defer until after init so `scratch-mixed-pitch-modes' has had a
  ;; chance to be overridden by the user's config.
  (add-hook 'emacs-startup-hook #'scratch-fonts--init-mixed-pitch-h)
  :config
  ;; Keep face heights consistent across the variable / fixed switch.
  (setq mixed-pitch-set-height t)
  ;; Keep `Info-quoted' (`'foo'`-style quotes in Info bodies) as fixed
  ;; -- they're typically code / identifiers, not prose.
  (add-to-list 'mixed-pitch-fixed-pitch-faces 'Info-quoted))
