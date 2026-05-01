;;; scratch-defaults.el --- sensible Emacs defaults -*- lexical-binding: t; -*-
;;
;; Framework-level defaults adapted from Doom's `doom-editor.el'. Override
;; individual settings in your user config (`~/.scratch.d/config.org')
;; if you don't want them.

;;;; File handling

(setq find-file-suppress-same-file-warnings t   ; "X and Y are the same file" is benign
      create-lockfiles nil                      ; no .#foo lockfiles in working dirs
      make-backup-files nil                     ; no foo~ backups; VC handles this
      kill-do-not-save-duplicates t             ; don't dup in kill-ring
      sentence-end-double-space nil             ; modern convention
      require-final-newline t)

;;;; Auto-save

;; Keep auto-save on (crash recovery) but redirect away from working dirs
;; so we don't litter projects with #foo# files.
(let ((auto-save-dir (expand-file-name "auto-save/" user-emacs-directory)))
  (make-directory auto-save-dir t)
  (setq auto-save-default t
        auto-save-include-big-deletions t
        auto-save-list-file-prefix auto-save-dir
        auto-save-file-name-transforms `((".*" ,auto-save-dir t))))

;;;; Formatting

(setq-default indent-tabs-mode nil               ; spaces, not tabs
              tab-width 4
              fill-column 80)

;;;; State persistence

;; recentf -- track recently opened files. Default save count (20) is too low.
(setq recentf-max-saved-items 200
      recentf-max-menu-items  25
      recentf-auto-cleanup    'never)
(with-eval-after-load 'recentf
  ;; Strip text properties before saving so the recentf file stays small.
  (add-to-list 'recentf-filename-handlers #'substring-no-properties))
(recentf-mode 1)

;; savehist -- persist minibuffer history, kill-ring, marks, etc.
(setq savehist-save-minibuffer-history t
      savehist-autosave-interval nil             ; save on kill only
      savehist-additional-variables
      '(kill-ring
        register-alist
        mark-ring global-mark-ring
        search-ring regexp-search-ring))
(savehist-mode 1)

;; save-place -- remember point position when re-opening files.
(save-place-mode 1)

(provide 'scratch-defaults)
;;; scratch-defaults.el ends here
