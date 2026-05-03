;;; modules/ui/info-colors/config.el -*- lexical-binding: t; -*-
;;
;; Colorize Info manual pages -- highlights headings, references, key
;; chords, etc. so `M-x info' / `C-h i' / `C-h r' (the Emacs manual)
;; aren't a wall of plain text. Activates lazily on the first Info
;; node selection.

(use-package info-colors
  :after info
  :commands info-colors-fontify-node
  :hook (Info-selection-hook . info-colors-fontify-node))

;; The built-in `Info-quoted' face (used for `'foo'`-style quotes
;; in Info bodies) defaults to `fixed-pitch-serif' with no foreground,
;; so quoted text reads as plain in most themes. Inherit from
;; `font-lock-string-face' so themes give it a visible accent color
;; (matches Doom's default polish). `face-spec-set' survives theme
;; reloads.
(with-eval-after-load 'info
  (face-spec-set 'Info-quoted '((t (:inherit font-lock-string-face)))))
