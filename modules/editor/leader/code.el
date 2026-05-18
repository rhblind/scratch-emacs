;;; modules/editor/leader/code.el -*- lexical-binding: t; -*-
;;
;; `SPC c' baseline -- generic prog-mode commands that work without
;; LSP. `:tools lsp' overlays LSP-aware variants on top (last-write-
;; wins) and `:checkers syntax' adds flycheck navigation.
;;
;; xref-based jumps work natively for elisp / etags / dumb-jump and,
;; when lsp-mode is attached to a buffer, route through lsp-mode's
;; xref backend automatically. So `c d' / `c D' do the right thing
;; whether or not an LSP server is running.

(map! :leader
  (:prefix-map ("c" . "code")
   :desc "compile"                 "c" #'compile
   :desc "recompile"               "C" #'recompile
   :desc "jump to definition"      "d" #'xref-find-definitions
   :desc "find references"         "D" #'xref-find-references
   :desc "find implementations"    "i" #'scratch/find-implementations
   :desc "find symbol (apropos)"   "/" #'xref-find-apropos
   :desc "describe symbol"         "k" #'scratch/describe-symbol-or-lsp
   :desc "format buffer/region"    "f" #'scratch/format
   :desc "rename symbol"                "r" #'scratch/rename
   :desc "trim trailing whitespace"   "w" #'delete-trailing-whitespace
   :desc "trim trailing blank lines"  "W" #'scratch/delete-trailing-newlines))
