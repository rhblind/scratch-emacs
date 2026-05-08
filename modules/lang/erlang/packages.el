;;; modules/lang/erlang/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; `erlang': the OTP-bundled Emacs package. Provides `erlang-mode',
;; erlang-shell, compilation commands, skeletons, and the standard
;; file associations (.erl, .hrl, .xrl, .yrl, .app.src, .escript).
;; Required dependency of `erlang-ts'.
(straight-use-package 'erlang)

;; `erlang-ts': tree-sitter layer. Provides `erlang-ts-mode' (derives
;; from `erlang-mode') with tree-sitter font-lock, navigation, and
;; experimental indentation. Requires Emacs 29.2+ and the `erlang'
;; tree-sitter grammar.
(straight-use-package 'erlang-ts)
