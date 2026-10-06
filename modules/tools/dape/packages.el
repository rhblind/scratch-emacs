;;; modules/tools/dape/packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; dape: Debug Adapter Protocol client with no dependencies outside
;; core Emacs. Adapters themselves come from the project environment
;; or toolchain at debug time (e.g. debugpy via `uv run --with
;; debugpy', delve, gdb, lldb-dap).
;;
;; Language modules opt into debugging with their own `+debug' flag
;; (checked against `(modulep! :tools dape)'): each registers its
;; adapter configs into `dape-configs' and binds localleader debug
;; keys. `:lang python' (debugpy-uv) is the reference wiring.

(straight-use-package 'dape)
