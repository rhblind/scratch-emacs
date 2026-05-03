;;; modules/tools/direnv/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; envrc.el (purcell): per-buffer integration with the `direnv' CLI.
;; Buffer-local env (via `process-environment') is set when entering
;; a directory with a trusted `.envrc' so subprocesses (compile,
;; LSP, magit shell-outs, ...) inherit the right tools.
(straight-use-package 'envrc)
