;;; modules/ui/fonts/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; mixed-pitch: render prose modes (org, markdown, info, ...) with a
;; variable-pitch font while keeping code blocks, tables, line numbers,
;; and similar regions in fixed-pitch.
(straight-use-package 'mixed-pitch)

;; +ligatures: font-level ligatures (-> => != etc.) via
;; composition-function-table. Requires a ligature-capable font
;; (Fira Code, JetBrains Mono, Cascadia Code, ...).
(when (modulep! +ligatures)
  (straight-use-package 'ligature))
