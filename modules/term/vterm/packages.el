;;; modules/term/vterm/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; vterm bundles a C dynamic module compiled on first load via cmake +
;; libtool + libvterm. Build prereqs (macOS): `brew install cmake libtool';
;; Linux: install your distro's `cmake' / `libtool' / `libvterm-dev'
;; equivalents. Without these, `vterm-module-compile' fails on first call.
(straight-use-package 'vterm)
