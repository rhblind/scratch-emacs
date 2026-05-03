;;; modules/checkers/syntax/config.el -*- lexical-binding: t; -*-
;;
;; Live syntax / linting checks via [[https://www.flycheck.org][flycheck]].
;;
;; Adapted from Doom's :checkers syntax, trimmed to flycheck-only (no
;; +flymake variant), without the Doom-specific popup-tip / posframe
;; layers (worth a flag if we want them later).

(use-package flycheck
  :defer t
  :commands (flycheck-list-errors flycheck-buffer global-flycheck-mode)
  :hook (emacs-startup . global-flycheck-mode)
  :init
  ;; emacs-lisp checker should see the running Emacs's load-path
  ;; (otherwise it can't find packages installed by straight).
  (setq flycheck-emacs-lisp-load-path 'inherit
        ;; Re-run on save / mode-change / idle-change. Drop `new-line'
        ;; (rechecking on every Enter is excessive).
        flycheck-check-syntax-automatically '(save mode-enabled idle-change)
        flycheck-idle-change-delay 1.0
        ;; Show error tooltips a touch faster than the default 0.9s.
        flycheck-display-errors-delay 0.25
        ;; Fringe indicators on the right (left fringe is reserved for
        ;; diff-hl when :emacs vc +gutter is on).
        flycheck-indication-mode 'right-fringe)

  :config
  ;; CVE-2024-53920: flycheck's emacs-lisp checker byte-compiles the
  ;; current buffer, which can execute code via macro expansion. Restrict
  ;; the elisp checker to project-tracked buffers (anything under
  ;; project.el). `eval' wrapped to delay `setf' macro expansion until
  ;; after flycheck loads (its gv setter isn't there at toplevel).
  (eval '(setf (flycheck-checker-get 'emacs-lisp 'predicate)
               (lambda ()
                 (and (not (bound-and-true-p no-byte-compile))
                      (project-current))))
        t)

  ;; Evil-friendly j/k in the error list buffer (normal state only).
  (when (modulep! :editor evil)
    (with-eval-after-load 'evil
      (map! :map flycheck-error-list-mode-map
        :n "j"      #'flycheck-error-list-next-error
        :n "k"      #'flycheck-error-list-previous-error
        :n "C-n"    #'flycheck-error-list-next-error
        :n "C-p"    #'flycheck-error-list-previous-error
        :n "RET"    #'flycheck-error-list-goto-error
        :n [return] #'flycheck-error-list-goto-error))))

;; flycheck-posframe: show error message in a child-frame near point
;; instead of only in the echo area. Auto-no-ops in TTY frames (no
;; child-frame support).
(use-package flycheck-posframe
  :hook (flycheck-mode . flycheck-posframe-mode)
  :config
  ;; Use nerd-icons-style prefixes when icons are available.
  (setq flycheck-posframe-warning-prefix "! "
        flycheck-posframe-error-prefix   "x "
        flycheck-posframe-info-prefix    "i ")
  ;; Don't show the popup in cases where it'd be disruptive.
  (when (modulep! :editor evil)
    (with-eval-after-load 'evil
      (add-hook 'flycheck-posframe-inhibit-functions #'evil-insert-state-p)
      (add-hook 'flycheck-posframe-inhibit-functions #'evil-replace-state-p)))
  ;; Avoid stacking the posframe on top of an active corfu popup.
  (when (modulep! :completion corfu)
    (add-hook 'flycheck-posframe-inhibit-functions
              (lambda () (and (boundp 'corfu--index) (>= corfu--index 0))))))

;;;; Bindings

;; Next / prev error work via the standard `next-error' machinery, which
;; flycheck wires into automatically. Bind in evil normal/motion states so
;; they're available everywhere code is.
(when (modulep! :editor evil)
  (with-eval-after-load 'evil
    (general-define-key
     :states '(normal motion visual)
     "]e" #'next-error
     "[e" #'previous-error)))

(when (modulep! :editor leader)
  (map! :leader
    (:prefix-map ("c" . "code")
     ;; If consult is enabled, route the error-list key through
     ;; `consult-flycheck' (richer picker / preview). Falls back to
     ;; flycheck's built-in list otherwise.
     :desc "list errors"        "x" (if (modulep! :completion vertico)
                                        #'consult-flycheck
                                      #'flycheck-list-errors)
     :desc "recheck buffer"     "X" #'flycheck-buffer
     :desc "next error"         "n" #'next-error
     :desc "prev error"         "p" #'previous-error
     :desc "explain error"      "e" #'flycheck-explain-error-at-point
     :desc "verify checkers"    "v" #'flycheck-verify-setup
     :desc "select checker"     "s" #'flycheck-select-checker
     :desc "disable checker"    "d" #'flycheck-disable-checker)))
