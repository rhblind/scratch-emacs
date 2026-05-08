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

(auto-image-file-mode 1)

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

;;;; Clipboard

;; Yank/kill flows through the OS clipboard. `select-enable-clipboard'
;; defaults to t in Emacs 29+; setting it explicitly guards against
;; accidental flips. `save-interprogram-paste-before-kill' captures
;; whatever's on the OS clipboard into the kill-ring just before we
;; overwrite it, so a kill never silently loses something the user had
;; just copied from another app.
(setq select-enable-clipboard t
      save-interprogram-paste-before-kill t)

;;;; Prompts

;; Override `yes-or-no-p' and `y-or-n-p' so all confirmation prompts
;; accept a single `y'/`n' and show the cursor in the echo area. The
;; default `y-or-n-p' reads via `read-event' which leaves the cursor
;; in the selected window (often NOT the echo area), making it look
;; like the prompt doesn't have focus.
(defun scratch--yes-or-no-p (prompt)
  "Read a single y/n with the cursor visible in the echo area."
  (let* ((prompt-str (concat (string-trim-right prompt) " (y or n) "))
         (cursor-in-echo-area t)
         answer)
    (message "%s" prompt-str)
    (setq answer (read-event))
    (while (not (memq answer '(?y ?Y ?n ?N)))
      (message "%s" prompt-str)
      (setq answer (read-event)))
    (message nil)
    (memq answer '(?y ?Y))))
(setq use-short-answers nil)
(advice-add 'yes-or-no-p :override #'scratch--yes-or-no-p)
(advice-add 'y-or-n-p    :override #'scratch--yes-or-no-p)

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

;;;; Auto-revert

;; Pull external file changes into Emacs buffers automatically. Without
;; this, switching branches (or any out-of-Emacs edit) leaves stale
;; buffers around until you `M-x revert-buffer'.
(setq auto-revert-verbose nil                ; don't echo "Reverting buffer X"
      auto-revert-check-vc-info t            ; keep modeline VC info fresh
      global-auto-revert-non-file-buffers t) ; dired, ibuffer, etc. too
(global-auto-revert-mode 1)

(defun scratch-auto-revert--prompt-if-modified-a (&rest _)
  "Prompt to revert when the file changed on disk but the buffer is modified."
  (when (and buffer-file-name
             (buffer-modified-p)
             (not (verify-visited-file-modtime)))
    (if (y-or-n-p (format "%s changed on disk; reload from file? " (buffer-name)))
        (revert-buffer :ignore-auto :noconfirm)
      (set-visited-file-modtime))))

(advice-add 'auto-revert-handler :before #'scratch-auto-revert--prompt-if-modified-a)

;;;; Line numbers
;;
;; Show line numbers in code-editing modes. Defaults to RELATIVE
;; (vim-style) since the framework targets evil users -- jumping by
;; `5j' / `12k' is the natural workflow there. Switch to absolute
;; with `(setq-default display-line-numbers-type t)' in your config
;; if you prefer.
;;
;; Avoid `global-display-line-numbers-mode': there are too many
;; transient / popup / TUI modes (magit, vterm, ibuffer, image-mode,
;; ...) where numbers are pure noise. Hook the canonical text-edit
;; modes instead, mirroring Doom.

(setq-default display-line-numbers-type 'relative
              display-line-numbers-width 3            ; pre-allocate gutter, no jump on grow
              display-line-numbers-widen t)           ; absolute count under narrowing

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;;;; Window display
;;
;; "If I ran a command that pops up a window, I'm probably about to
;; interact with it." Steal focus for help-style buffers (built-in
;; toggle) and a small allow-list of explicit-action listings.
;; Compilation / messages / warnings are intentionally NOT included --
;; those pop up in the background and shouldn't yank point mid-edit.

(setq help-window-select t)               ; *Help*, *Apropos*, *info*, ...

(dolist (name '("\\*Process List\\*"
                "\\*Buffer List\\*"
                "\\*Occur\\*"
                "\\*Async Shell Command\\*"))
  (add-to-list 'display-buffer-alist
               `(,name
                 (display-buffer-reuse-window display-buffer-pop-up-window)
                 ;; Built-in alist key (Emacs 28+): selects the new window
                 ;; on `post-command-hook' so any setup the command runs
                 ;; first lands before focus shifts.
                 (post-command-select-window . t))))

(provide 'scratch-defaults)
;;; scratch-defaults.el ends here
