;;; modules/emacs/dired/config.el -*- lexical-binding: t; -*-
;;
;; Built-in `dired' tweaks: smart copy/move targets, recursive ops,
;; GNU-`ls'-style flags (with `gls' fallback on macOS for a sortable
;; listing), async copy/move, dotfile toggling, recent-dirs picker,
;; nerd-icons in the listing, plus a leader binding for `dired-jump'.
;;
;; Adapted from Doom's `:emacs dired'.

(use-package dired
  :straight (:type built-in)
  :defer t
  :commands (dired dired-jump)
  :init
  (setq dired-dwim-target t                 ; suggest the OTHER dired window's path on move/copy
        dired-auto-revert-buffer #'dired-buffer-stale-p
        dired-kill-when-opening-new-dired-buffer t
        dired-recursive-copies  'always
        dired-recursive-deletes 'top
        dired-create-destination-dirs 'ask  ; prompt to mkdir on copy/move
        ;; Image cache under user-emacs-directory.
        image-dired-dir
        (expand-file-name "image-dired/" user-emacs-directory)
        image-dired-db-file
        (expand-file-name "image-dired/db.el" user-emacs-directory)
        image-dired-thumb-size 150)
  :config
  ;; ls flags. GNU `ls' supports `-v --group-directories-first'; BSD
  ;; `ls' (macOS) doesn't, so use `gls' from coreutils when available.
  (let ((args '("-ahl" "-v" "--group-directories-first")))
    (when (eq system-type 'darwin)
      (if-let* ((gls (executable-find "gls")))
          (setq insert-directory-program gls)
        ;; No gls -- fall back to plain `-ahl' (BSD-compatible).
        (setq args (list (car args)))))
    (setq dired-listing-switches (string-join args " "))
    ;; Strip the GNU flags over TRAMP -- the remote `ls' may not
    ;; support them, leaving an empty dired buffer. Local listings
    ;; keep the full set.
    (add-hook 'dired-mode-hook
              (lambda ()
                (when (file-remote-p default-directory)
                  (setq-local dired-actual-switches (car args))))))

  ;; Don't disable dired-find-alternate-file (`a' opens in same buffer).
  (put 'dired-find-alternate-file 'disabled nil)

  ;; Wdired: edit filenames as text. Doom-style `C-c C-e' alias for
  ;; consistency with vertico/wgrep/etc.
  (define-key dired-mode-map (kbd "C-c C-e") #'wdired-change-to-wdired-mode))

;; Async copy/move/rename so big operations don't block Emacs.
;; `dired-async' ships with the `async' package (a transitive dep
;; of magit, so it's already on disk).
(use-package dired-async
  :straight nil
  :after dired
  :config (dired-async-mode 1))

;; dired-hide-dotfiles: `H' toggles `.'-prefixed entries.
(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode))

;; dired-recent: `r' picks from previously visited dirs.
(use-package dired-recent
  :after dired
  :init
  (setq dired-recent-directories-file
        (expand-file-name "dired-recent" user-emacs-directory))
  :config
  (dired-recent-mode 1)
  ;; Free up `C-x C-d' (dired-recent's default binding) -- conflicts
  ;; with `consult-dir' / dired's own `C-x d'. The user reaches
  ;; recent dirs via the `r' evil binding below instead.
  (define-key dired-recent-mode-map (kbd "C-x C-d") nil))

;; nerd-icons-dired: overlay-based file/dir icons in the listing.
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode)
  :config
  ;; When `:ui treemacs' is active, align dired's visual style with the
  ;; treemacs nerd-icons theme: same directory glyph, face, and muted
  ;; directory-name coloring.
  (when (modulep! :ui treemacs)
    (with-eval-after-load 'treemacs-nerd-icons
      (setq nerd-icons-dired-dir-icon-function
            (lambda (_dir &rest _args)
              (nerd-icons-sucicon "nf-custom-folder_oct"
                                  :face 'treemacs-nerd-icons-file-face
                                  :height nerd-icons-dired-icon-size)))
      (set-face-attribute 'dired-directory nil
                          :foreground 'unspecified
                          :inherit 'treemacs-directory-face))))

;;;; +preview: live file preview as point moves

(when (modulep! +preview)
  (use-package dired-preview
    :after dired
    :init
    (setq dired-preview-delay 0.2
          dired-preview-max-size (* 512 1024)
          dired-preview-ignored-extensions-regexp
          (rx "." (or "elc" "pyc" "o" "so" "dylib" "a"
                      "gz" "tar" "xz" "zst" "bz2" "zip"
                      "png" "jpg" "jpeg" "gif" "bmp" "svg" "webp"
                      "mp3" "mp4" "mkv" "avi" "mov" "wav" "flac"
                      "pdf" "doc" "docx" "xls" "xlsx"
                      "sqlite" "db")
              eos)))
  (when (modulep! :editor evil)
    (with-eval-after-load 'dired
      (with-eval-after-load 'evil-collection
        (evil-collection-define-key 'normal 'dired-mode-map
          "p" #'dired-preview-mode)))))

;;;; Compress / extract: extra archive formats

(with-eval-after-load 'dired-aux
  (setq dired-compress-file-alist
        (append dired-compress-file-alist
                '(("\\.tar\\.gz\\'"  . "tar -cf - %i | gzip -c9 > %o")
                  ("\\.tar\\.bz2\\'" . "tar -cf - %i | bzip2 -c9 > %o")
                  ("\\.tar\\.xz\\'"  . "tar -cf - %i | xz -c9 > %o")
                  ("\\.tar\\.zst\\'" . "tar -cf - %i | zstd -19 -o %o")
                  ("\\.zip\\'"       . "zip %o -r --filesync %i")))))

;;;; Evil bindings inside dired

(when (modulep! :editor evil)
  (with-eval-after-load 'dired
    (with-eval-after-load 'evil-collection
      ;; vim-style nav: `h' up, `l' enter, plus our additions.
      (evil-collection-define-key 'normal 'dired-mode-map
        "h" #'dired-up-directory
        "l" #'dired-find-file
        "r" #'dired-recent-open
        "G" (if (fboundp 'consult-dir) #'consult-dir #'goto-line)
        "K" #'dired-do-kill-lines))
    (with-eval-after-load 'dired-hide-dotfiles
      (evil-collection-define-key 'normal 'dired-mode-map
        "H" #'dired-hide-dotfiles-mode))))

;;;; Leader: `SPC -' jumps to dired for current buffer's directory

(when (modulep! :editor leader)
  (map! :leader
        :desc "dired (jump)" "-" #'dired-jump))
