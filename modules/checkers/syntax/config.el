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
  (which-key-add-key-based-replacements "C-c !" "flycheck")
  ;; Org 9.7+ returns propertized strings for line numbers in org-lint
  ;; results; flycheck 36.0 passes them straight to
  ;; `flycheck-error-new-at' which expects integers. The override runs
  ;; here (inside flycheck's :config) rather than after org-lint loads,
  ;; because the checker's :start fires before org-lint provides its
  ;; feature.
  (if (string= flycheck-version "36.0")
      (put 'org-lint 'flycheck-start
           (lambda (checker callback)
             (condition-case err
                 (let ((errors
                        (delq nil
                              (mapcar
                               (lambda (e)
                                 (pcase e
                                   (`(,_n [,line ,_trust ,desc ,_checker])
                                    (flycheck-error-new-at
                                     (if (stringp line)
                                         (string-to-number line)
                                       line)
                                     nil 'info desc
                                     :checker checker))
                                   (_
                                    (flycheck-error-new-at
                                     1 nil 'warning
                                     (format "Unexpected org-lint format: %S" e)
                                     :checker checker))))
                               (org-lint)))))
                   (funcall callback 'finished errors))
               (error (funcall callback 'errored
                               (error-message-string err))))))
    (display-warning 'scratch
      (format "flycheck upgraded to %s; the org-lint workaround in \
checkers/syntax/config.el may be safe to remove"
              flycheck-version)
      :info))

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
  (let ((list-errors-cmd (if (modulep! :completion vertico)
                             #'consult-flycheck
                           #'flycheck-list-errors)))
    (map! :leader
      (:prefix-map ("c" . "code")
       :desc "list errors"        "x" list-errors-cmd
       :desc "next error"         "n" #'next-error
       :desc "prev error"         "p" #'previous-error
       :desc "explain error"      "e" #'flycheck-explain-error-at-point))))
;; Less-frequent flycheck commands (recheck-buffer, verify-setup,
;; select-checker, disable-checker) are reachable via `M-x flycheck-*'.
;; They were dropped from the leader to keep `SPC c' tidy: `c C' is
;; recompile (baseline), `c d' is jump-to-definition (baseline), etc.
