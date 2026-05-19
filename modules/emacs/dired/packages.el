;;; modules/emacs/dired/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Dired companions:
;;   - `dired-hide-dotfiles': `H' toggles `.'-prefixed entries.
;;   - `dired-recent':        `r' opens a completing-read picker over
;;                            previously visited dirs; persists to
;;                            `dired-recent-directories-file' under
;;                            `user-emacs-directory'.
(straight-use-package 'dired-hide-dotfiles)
(straight-use-package 'dired-recent)

(straight-use-package 'nerd-icons-dired)

(when (modulep! +preview)
  (straight-use-package 'dired-preview))
