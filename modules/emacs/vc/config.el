;;; modules/emacs/vc/config.el -*- lexical-binding: t; -*-
;;
;; Version control: built-in `vc' tweaks, magit (always), forge (with flag),
;; smerge-mode auto-enable, git-timemachine, browse-at-remote, git-modes.
;;
;; Adapted from Doom's :emacs vc, minus Doom-specific helpers
;; (`set-popup-rules!', `:localleader', `defadvice!') and the Emacs 31
;; vc-git--call signature compat hack.
;;
;; Flags:
;;   +forge  -- enable forge (GitHub / GitLab issues + PRs inside magit).
;;              Requires an authinfo entry for your forge token; see
;;              C-h f forge-add-repository.

;;;; Built-in vc

;; Edit symlinks directly, don't auto-follow.
(setq vc-follow-symlinks nil)

;; Git only -- every backend in this list is probed for every TRAMP buffer
;; / file open, so trimming it pays.
(setq-default vc-handled-backends '(Git))

;; node_modules is huge; skip it for vc operations.
(setq-default vc-ignore-dir-regexp
              (format "%s\\|%s"
                      locate-dominating-stop-dir-regexp
                      "[/\\\\]node_modules"))

;;;; Magit

(use-package magit
  :defer t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :config
  (setq magit-diff-refine-hunk t                  ; fine-grained diffs within hunks
        magit-save-repository-buffers 'dontask))  ; auto-save buffers, no prompt

;; Forge -- GitHub / GitLab integration on top of magit.
(when (modulep! +forge)
  (use-package forge
    :after magit))

;;;; smerge -- auto-enable on conflict markers

(defun scratch-vc--maybe-enable-smerge ()
  "Enable `smerge-mode' if the buffer contains git conflict markers."
  (unless (bound-and-true-p smerge-mode)
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " nil t)
        (smerge-mode 1)))))

(use-package smerge-mode
  :defer t
  :init
  (add-hook 'find-file-hook #'scratch-vc--maybe-enable-smerge)
  :config
  ;; Smerge actions on the localleader: SPC m n / , n / etc. when point is
  ;; in a buffer where smerge-mode is active.
  (when (modulep! :editor leader)
    (map! :map smerge-mode-map :localleader
          "n" #'smerge-next
          "p" #'smerge-prev
          "r" #'smerge-resolve
          "a" #'smerge-keep-all
          "b" #'smerge-keep-base
          "l" #'smerge-keep-lower
          "u" #'smerge-keep-upper
          "E" #'smerge-ediff
          "R" #'smerge-refine
          "RET" #'smerge-keep-current)))

;;;; log-view -- evil-friendly j/k navigation between commits

(with-eval-after-load 'log-view
  (define-key log-view-mode-map (kbd "j") #'log-view-msg-next)
  (define-key log-view-mode-map (kbd "k") #'log-view-msg-prev))

;;;; vc-annotate -- q kills the buffer instead of burying it

(with-eval-after-load 'vc-annotate
  (define-key vc-annotate-mode-map [remap quit-window] #'kill-current-buffer))

;;;; git-timemachine -- step through file history

(use-package git-timemachine
  :defer t
  :config
  ;; Show revision details in the header-line as well so a stale timemachine
  ;; buffer is visually obvious.
  (setq git-timemachine-show-minibuffer-details t)

  ;; `delay-mode-hooks' suppresses font-lock-mode in newer Emacs; force it.
  (add-hook 'git-timemachine-mode-hook #'font-lock-mode)

  ;; Re-evaluate evil keymaps so timemachine bindings activate.
  (with-eval-after-load 'evil
    (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps)))

;;;; browse-at-remote

(use-package browse-at-remote
  :defer t
  :config
  ;; Prefer commit hashes (permalinks) over branch names.
  (setq browse-at-remote-prefer-symbolic nil
        ;; Don't auto-include the line number; require a region.
        browse-at-remote-add-line-number-if-no-region-selected nil)

  ;; Recognise codeberg.org and arbitrary gitlab.* hosts (Doom's tweaks).
  (add-to-list 'browse-at-remote-remote-type-regexps
               '(:host "^codeberg\\.org$" :type "codeberg"))
  (add-to-list 'browse-at-remote-remote-type-regexps
               '(:host "^gitlab\\." :type "gitlab") 'append))

;;;; git-modes (gitconfig-mode, gitignore-mode, gitattributes-mode)

(use-package git-modes :defer t)

;;;; Leader bindings (this module owns the SPC g submenu)

(when (modulep! :editor leader)
  (map! :leader
    "g"   '(:ignore t                :which-key "git")
    "g g" '(magit-status             :which-key "magit status")
    "g d" '(magit-dispatch           :which-key "magit dispatch")
    "g l" '(magit-log-current        :which-key "log (current branch)")
    "g L" '(magit-log-buffer-file    :which-key "log (buffer file)")
    "g b" '(magit-blame              :which-key "blame")
    "g f" '(magit-file-dispatch      :which-key "file dispatch")
    "g r" '(browse-at-remote         :which-key "browse at remote")
    "g R" '(browse-at-remote-kill    :which-key "copy remote URL")
    "g t" '(git-timemachine          :which-key "timemachine")))
