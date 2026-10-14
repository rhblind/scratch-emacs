;;; modules/completion/corfu/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; corfu's extensions (corfu-history, corfu-popupinfo, ...) live in the
;; `extensions/' subdirectory of the corfu repo, not as separate MELPA
;; packages. Override the recipe to put them on the load-path.
(straight-use-package
 '(corfu :type git :host github :repo "minad/corfu"
         :files (:defaults "extensions/*.el")))

;; Icon glyphs in the corfu popup margin.
(straight-use-package 'nerd-icons-corfu)

;; cape -- completion-at-point extensions (file paths, dabbrev, elisp
;; blocks in org/markdown, etc.). Composes with the existing capfs.
(straight-use-package 'cape)

;; corfu's default popup uses child-frames, which don't render in a TTY.
;; corfu-terminal swaps in an overlay-based popup for terminal frames.
;; Only needed below Emacs 31, where corfu grew native TTY support;
;; installing it on 31+ makes corfu warn at load time. A daemon may
;; still serve TTY emacsclients later even if it starts without a
;; display, hence the version guard rather than a display check.
(when (< emacs-major-version 31)
  (straight-use-package 'corfu-terminal))
