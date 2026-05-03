;;; modules/editor/format/config.el -*- lexical-binding: t; -*-
;;
;; [[https://github.com/radian-software/apheleia][apheleia]]: format every buffer on save, using the language's
;; canonical formatter (prettier, gofmt, csharpier, mix format, ...).
;; Apheleia ships a comprehensive list out of the box; per-language
;; modules override individual entries when the upstream defaults
;; need tweaking (e.g. `:lang elixir' wraps `mix format' so it runs
;; from the project root with stderr silenced).
;;
;; Async by design: the formatter runs in a subprocess and the diff
;; is applied without disrupting point/mark/window state. No editor
;; freeze, even on large files.

(use-package apheleia
  :demand t
  :config
  ;; Format every save automatically. Buffers in modes apheleia knows
  ;; how to format get reformatted; everything else is untouched.
  ;; Activated eagerly (rather than deferred) so a buffer saved during
  ;; the first few seconds of an Emacs session still gets formatted --
  ;; a deferred activation would silently no-op if the user's first
  ;; save raced ahead of the timer.
  (apheleia-global-mode 1))

;;;; LSP format-on-save (preferred over apheleia when available)
;;
;; When `:tools lsp' is enabled and an LSP server attached to the
;; buffer advertises `textDocument/formatting', use it for
;; format-on-save instead of apheleia. LSP formatting is in-process
;; (no subprocess spawn, no recompile chatter, no shell pipeline) so
;; it's much faster and avoids the class of bugs where apheleia's
;; subprocess pollutes stdout (e.g. `mix format' triggering a recompile
;; and emitting elixir's compile chatter into the formatted result).
;;
;; Falls back to apheleia automatically: in buffers without an LSP
;; server (one-off scripts, languages without an LSP, server failed
;; to start) the hook below never fires, apheleia-mode stays on, and
;; the buffer formats via whichever apheleia formatter is registered
;; for the major-mode.
;;
;; Set `scratch-format-prefer-lsp' to nil before `scratch!' runs to
;; opt out -- some users prefer canonical CLI formatters (prettier /
;; gofmt / etc.) over LSP-server-provided formatting, even when both
;; are available.

(defvar scratch-format-prefer-lsp t
  "When non-nil, prefer LSP `textDocument/formatting' over apheleia
in buffers managed by `lsp-mode'. Apheleia handles every other buffer
(no LSP, or server doesn't advertise formatting). Set to nil before
`scratch!' to disable and use apheleia universally.")

(defun scratch-format--prefer-lsp ()
  "Switch this buffer's format-on-save to LSP instead of apheleia.
Runs from `lsp-after-open-hook' so we know the server's capabilities.
Inhibits apheleia in this buffer and wires `lsp-format-buffer' to a
buffer-local `before-save-hook'. Generic across languages: any LSP
server that implements `textDocument/formatting' wins; per-language
modules don't need to wire this themselves."
  (when (and scratch-format-prefer-lsp
             (bound-and-true-p lsp-mode)
             (fboundp 'lsp-feature?)
             (lsp-feature? "textDocument/formatting"))
    (setq-local apheleia-inhibit t)
    (when (bound-and-true-p apheleia-mode)
      (apheleia-mode -1))
    (add-hook 'before-save-hook #'lsp-format-buffer nil 'local)))

(when (modulep! :tools lsp)
  (with-eval-after-load 'lsp-mode
    (add-hook 'lsp-after-open-hook #'scratch-format--prefer-lsp)))

;; Manual format via `SPC c f' goes through `scratch/format-region-or
;; -buffer' (in `lisp/scratch-code.el'), which prefers apheleia when
;; the buffer's `apheleia-mode' is on, else falls back to lsp / indent.
;; In LSP buffers apheleia-mode is off (per the hook above), so manual
;; format uses LSP -- consistent with format-on-save.
