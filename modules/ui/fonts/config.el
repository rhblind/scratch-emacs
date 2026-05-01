;;; modules/ui/fonts/config.el -*- lexical-binding: t; -*-
;;
;; Comfortable default font sizing. Emacs' built-in default is small on most
;; modern HiDPI displays; 14pt is a good compromise across screens. Family
;; is left at the system default unless overridden.
;;
;; Overrides (set BEFORE calling `scratch!'):
;;   scratch-font-height           -- default 140 (= 14pt; units are 1/10 pt).
;;   scratch-font-family           -- default nil (system monospace).
;;   scratch-font-variable-family  -- default nil (system variable-pitch).

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
