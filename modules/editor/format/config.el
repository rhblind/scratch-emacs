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

;;;; Formatter priority: project config > LSP > apheleia defaults
;;
;; When a project ships a formatter config file (.editorconfig,
;; .prettierrc, rustfmt.toml, ...) the user has explicitly chosen how
;; code should be formatted. Apheleia runs the right formatter per
;; major-mode, and most formatters read these config files natively,
;; so apheleia stays active.
;;
;; When NO project config is found and `:tools lsp' is enabled, LSP
;; `textDocument/formatting' takes over. LSP formatting is in-process
;; (no subprocess spawn, no recompile chatter) and a good default for
;; projects that haven't chosen a specific formatter.
;;
;; Apheleia remains the final fallback for buffers without LSP or
;; without a recognised formatter config.
;;
;; Set `scratch-format-prefer-lsp' to nil before `scratch!' to use
;; apheleia unconditionally (skipping LSP even in unconfigured projects).

(defvar scratch-format-prefer-lsp t
  "When non-nil AND the project has no explicit formatter config,
prefer LSP `textDocument/formatting' over apheleia. Projects that
ship a formatter config file always use apheleia regardless of this
setting. Set to nil before `scratch!' to use apheleia universally.")

(defvar scratch-format-config-files
  '(".editorconfig"
    ".prettierrc" ".prettierrc.json" ".prettierrc.yml" ".prettierrc.yaml"
    ".prettierrc.js" ".prettierrc.cjs" ".prettierrc.mjs" ".prettierrc.toml"
    "prettier.config.js" "prettier.config.cjs" "prettier.config.mjs"
    "biome.json" "biome.jsonc"
    "deno.json" "deno.jsonc"
    ".clang-format"
    "rustfmt.toml" ".rustfmt.toml"
    ".formatter.exs")
  "Formatter config files that signal a project has chosen a specific
formatter. When any of these exist in the project root, apheleia
runs the project's formatter instead of deferring to LSP.
Add entries for additional tools as needed.")

(defun scratch-format--project-has-formatter-config-p ()
  "Return non-nil if the current project has a formatter config file."
  (when-let* ((proj (project-current))
              (root (project-root proj)))
    (cl-some (lambda (file)
               (file-exists-p (expand-file-name file root)))
             scratch-format-config-files)))

(defun scratch-format--prefer-lsp ()
  "Switch this buffer's format-on-save to LSP instead of apheleia.
Only activates when the project has no explicit formatter config.
Runs from `lsp-after-open-hook' so we know the server's capabilities."
  (when (and scratch-format-prefer-lsp
             (bound-and-true-p lsp-mode)
             (fboundp 'lsp-feature?)
             (lsp-feature? "textDocument/formatting")
             (not (scratch-format--project-has-formatter-config-p)))
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
;; In LSP buffers without formatter config, apheleia-mode is off (per
;; the hook above), so manual format uses LSP, consistent with
;; format-on-save.
