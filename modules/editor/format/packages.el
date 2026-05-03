;;; modules/editor/format/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; apheleia: async formatter framework. Runs the right formatter
;; (prettier, gofmt, csharpier, mix format, ...) per major mode on
;; save. Async = no editor freeze even on big files.
(straight-use-package 'apheleia)
