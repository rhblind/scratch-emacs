;;; modules/lang/csharp/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; `csharp-ts-mode' ships built-in (Emacs 29+); no external mode pkg.
;; `dotnet' provides convenience commands for `dotnet build / run / test'
;; from inside Emacs.
(straight-use-package 'dotnet)
