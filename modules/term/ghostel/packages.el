;;; modules/term/ghostel/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; ghostel bundles a native Zig module that auto-downloads a prebuilt
;; binary on first use. No external toolchain required (unlike vterm).
;; Build from source: Zig 0.15.2+, then `zig build' from the repo root.
(straight-use-package
 '(ghostel :type git :host github :repo "dakra/ghostel"
           :files ("lisp/*.el" "etc" "extensions/evil-ghostel/*.el")))
