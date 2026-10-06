;;; modules/lang/python/config.el -*- lexical-binding: t; -*-
;;
;; Python support. Built-in `python-ts-mode' (Emacs 29+, tree-sitter
;; based) for `.py' / `.pyw' / `.pyi'; tree-sitter only, no legacy
;; fallback.
;;
;; Tooling follows the Astral stack:
;;
;;   - uv -- projects / venvs / dependency management. The module
;;     detects the project interpreter for inferior shells and pytest:
;;     nearest ancestor `.venv/bin/python' when it exists, else
;;     `uv run python'. The LSP servers resolve the `.venv' themselves,
;;     no plumbing needed.
;;
;; Monorepos: everything resolves per-file, walking up from the
;; buffer's directory to the project boundary -- the nearest
;; pyproject.toml / uv.lock owns the buffer (same convention as the
;; rust module's nearest-Cargo.toml). pytest is pinned to that root
;; via `python-pytest-project-root-override' instead of the git root,
;; and `.venv' discovery walks ancestors, so uv workspaces (root
;; .venv, member pyproject.toml) resolve to the right environment.
;; Worktrees need no language-specific handling: `:tools lsp' keeps
;; per-worktree servers and filters cross-worktree results
;; framework-wide.
;;
;;   - ty -- LSP types / navigation / completions / inlay hints, via
;;     lsp-mode's built-in `lsp-python-ty' client (`ty server').
;;
;;   - ruff -- LSP lint + organize-imports + fix-all, via lsp-mode's
;;     built-in `lsp-ruff' ADD-ON client (`ruff server'); it starts
;;     alongside ty in the same buffer. Also the formatter through
;;     apheleia (`ruff format' + `ruff check --select I --fix' chain)
;;     and, when an LSP server is attached, through
;;     `textDocument/formatting' (the `:editor format' module prefers
;;     LSP when the project has no formatter config file; the ruff
;;     server reads pyproject.toml / ruff.toml either way).
;;
;; Install the server binaries once:
;;   uv tool install ty ruff
;;   (or: brew install ruff && uv tool install ty)
;;
;; Tests run through python-pytest (localleader `t' prefix, mirroring
;; `:lang elixir''s exunit). Debugging goes through dape with the
;; `+debug' flag plus the `:tools dape' module: a `debugpy-uv' adapter
;; config injects debugpy via `uv run --with debugpy', so debugpy does
;; not have to be a project dependency.

;; Tell `:editor tree-sitter' that we want the python grammar managed
;; by treesit-auto. Idempotent; no-op when tree-sitter isn't enabled.
(add-to-list 'scratch-treesit-want 'python)

;; Grammar source as a fallback for users without `:editor tree-sitter'
;; (treesit-auto otherwise provides this via its recipe list). Lets
;; `M-x treesit-install-language-grammar RET python' work standalone.
;; No rev pin: current tree-sitter-python works with the ABI Emacs 30
;; ships.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(python "https://github.com/tree-sitter/tree-sitter-python")))

;; Once the grammar is installed, Emacs' own python.el routes `.py' /
;; `.pyw' / `.pyi' (and shebang'd files) to `python-ts-mode' by
;; itself, so no auto-mode-alist / remap entries are needed here.

;;;; Project interpreter resolution (uv-aware)

(defun scratch-python--buffer-dir ()
  "Directory the current buffer's file lives in, or `default-directory'."
  (or (and buffer-file-name (file-name-directory buffer-file-name))
      default-directory))

(defun scratch-python--project-boundary ()
  "Outer boundary for project discovery: the `project-current' root.
Bounds the `.venv' ancestor walk below so a stray venv above the
repo (e.g. `$HOME/.venv') is never picked up."
  (when-let* ((proj (project-current nil (scratch-python--buffer-dir))))
    (project-root proj)))

(defun scratch-python--project-root ()
  "Return this buffer's NEAREST python project root, or nil.
Looks for `uv.lock' or `pyproject.toml' walking up from the buffer's
directory. In a monorepo this is the package that owns the buffer,
not the git root -- the same convention as the rust module's
nearest-Cargo.toml resolution."
  (let ((dir (scratch-python--buffer-dir)))
    (or (locate-dominating-file dir "uv.lock")
        (locate-dominating-file dir "pyproject.toml"))))

(defun scratch-python--venv-python ()
  "Return the nearest ancestor's `.venv/bin/python', or nil.
Checks every directory between the buffer's directory and the
project boundary, nearest first. Covers both flat projects and uv
workspaces (member package has its own pyproject.toml but only the
workspace root has the `.venv')."
  (when-let* ((boundary (scratch-python--project-boundary)))
    (let ((dir (file-name-as-directory (scratch-python--buffer-dir)))
          (result nil))
      (while (and (not result) (string-prefix-p boundary dir))
        (let ((python (expand-file-name ".venv/bin/python" dir)))
          (setq result (and (file-exists-p python) python))
          (unless (or result (string= dir boundary))
            (setq dir (file-name-as-directory
                       (expand-file-name ".." dir))))))
      result)))

(defun scratch-python--use-uv-p ()
  "Whether this buffer's project is managed by uv and uv is installed."
  (and (executable-find "uv")
       (scratch-python--project-root)))

(defun scratch-python--setup-interpreter ()
  "Point `python-shell-interpreter' at this project's environment.
Precedence: the nearest ancestor `.venv/bin/python' (created by
`uv sync' / `uv venv'), then `uv run python' (which materializes
the environment on demand), then whatever the global default is."
  (require 'python)
  (cond
   ((scratch-python--venv-python)
    (setq-local python-shell-interpreter (scratch-python--venv-python)))
   ((scratch-python--use-uv-p)
    (setq-local python-shell-interpreter "uv")
    (setq-local python-shell-interpreter-args "run python -i"))))

(add-hook 'python-ts-mode-hook #'scratch-python--setup-interpreter)

;;;; LSP (ty + ruff)

(when (modulep! :tools lsp)
  ;; Opt `python-ts-mode' into `:tools lsp' auto-attach; `lsp-deferred'
  ;; hooks it on entry.
  (add-to-list 'scratch-lsp-auto-modes 'python-ts-mode)

  ;; Python build / cache artifacts; keeps the file watcher under
  ;; `lsp-file-watch-threshold' on real projects.
  (with-eval-after-load 'lsp-mode
    (dolist (pat '("[/\\\\]\\.venv\\'"           ; uv / virtualenv env
                   "[/\\\\]__pycache__\\'"       ; bytecode cache
                   "[/\\\\]\\.eggs\\'"           ; legacy setuptools
                   "[/\\\\]build\\'"             ; setuptools / wheel
                   "[/\\\\]dist\\'"
                   "[/\\\\]\\.pytest_cache\\'"
                   "[/\\\\]\\.ruff_cache\\'"
                   "[/\\\\]\\.mypy_cache\\'"
                   "[/\\\\]\\.tox\\'"
                   "[/\\\\]\\.nox\\'"
                   "[/\\\\]htmlcov\\'"))         ; coverage.py report
      (add-to-list 'lsp-file-watch-ignored-directories pat)))

  ;; Both clients (`lsp-python-ty' and `lsp-ruff') register themselves
  ;; as `:add-on?' clients inside lsp-mode, and `lsp--find-clients'
  ;; starts every add-on client even when no primary server matches,
  ;; so ty + ruff coexist out of the box. Nothing to register here.

  ;; The ruff server contributes `textDocument/formatting'; ty does
  ;; not. The `:editor format' module's LSP-preference logic therefore
  ;; formats via ruff when a server is attached, and via apheleia
  ;; otherwise -- both paths run `ruff format'.

  ;; Diagnostics from both servers surface through flycheck's `lsp'
  ;; checker when `:checkers syntax' is on (it aggregates across all
  ;; workspaces attached to the buffer); through flymake otherwise.
  ;; Nothing to wire.
  )

;;;; Formatting (apheleia fallback)

;; apheleia's default python formatter is `black'; remap to the ruff
;; chain instead: `ruff check --select I --fix' (import ordering) then
;; `ruff format'. Applies when NO LSP server is attached (`:editor
;; format' prefers LSP formatting otherwise). Buffers are always in
;; `python-ts-mode' per this module's ts-only policy.
(with-eval-after-load 'apheleia
  (setf (alist-get 'python-ts-mode apheleia-mode-alist)
        '(ruff-isort ruff)))

;;;; Tests (python-pytest)

(defun scratch-python--setup-pytest ()
  "Pick the right pytest invocation and root for this buffer's project.
Executable: `uv run pytest' for uv projects (resolves the project
environment, even without a venv on disk yet), the project venv's
own pytest when one exists, otherwise upstream's default (`pytest'
on PATH). Root: pinned to the NEAREST python project root via
`python-pytest-project-root-override', so in a monorepo tests run
from the package that owns the buffer instead of the git root
(upstream roots via `project-current', which is the git root)."
  (require 'python-pytest)
  (cond
   ((scratch-python--use-uv-p)
    (setq-local python-pytest-executable "uv run pytest"))
   ((when-let* ((python (scratch-python--venv-python))
                (pytest (expand-file-name "bin/pytest"
                                          (file-name-directory python))))
      (and (file-exists-p pytest)
           (setq-local python-pytest-executable pytest)))))
  (when-let* ((root (scratch-python--project-root)))
    (setq-local python-pytest-project-root-override root)))

(add-hook 'python-ts-mode-hook #'scratch-python--setup-pytest)

;;;; Debugging (dape, with `+debug')

;; Flag check at top level: `(modulep! +debug)' is dynamic-scoped and
;; only resolves while this module's config.el is loading (the 2-arg
;; form used inside is safe anywhere).
(when (modulep! +debug)
  (when (modulep! :tools dape)
    ;; Additive: upstream's `debugpy' config (plain `python -m
    ;; debugpy.adapter', debugpy pre-installed in the environment)
    ;; stays untouched. `debugpy-uv' injects debugpy through uv, so
    ;; the adapter runs in the PROJECT's interpreter without debugpy
    ;; having to be a dependency. The debugged program is launched by
    ;; the adapter with that same interpreter, landing in the right
    ;; environment automatically.
    (with-eval-after-load 'dape
      (let ((ensure (lambda (config) (dape-ensure-command config))))
        (add-to-list
         'dape-configs
         (list 'debugpy-uv
               'modes '(python-mode python-ts-mode)
               'ensure ensure
               'command "uv"
               'command-args '("run" "--with" "debugpy" "python"
                               "-m" "debugpy.adapter"
                               "--host" "0.0.0.0" "--port" :autoport)
               'port :autoport
               :request "launch"
               :type "python"
               :cwd 'dape-cwd
               :program 'dape-buffer-default
               :args []
               :justMyCode nil
               :console "integratedTerminal"
               :showReturnValue t
               :stopOnEntry nil))))))

;;;; Localleader bindings

(when (modulep! :editor leader)
  ;; Test runner bindings (python-pytest). Same shape as the elixir
  ;; module's exunit prefix. NOTE: unlike rust-ts-mode / elixir-ts-mode
  ;; (each its own file), `python-ts-mode' lives in python.el, which
  ;; provides `python' -- so the after-load hook must watch `python'.
  (with-eval-after-load 'python
    (map! :map python-ts-mode-map :localleader
          (:prefix-map ("t" . "test")
           :desc "all tests"            "a" #'python-pytest
           :desc "test file"            "v" #'python-pytest-file
           :desc "test at point"        "s" #'python-pytest-run-def-or-class-at-point
           :desc "repeat last"          "r" #'python-pytest-repeat
           :desc "last failed"          "l" #'python-pytest-last-failed
           :desc "dispatch menu"        "d" #'python-pytest-dispatch))
    ;; LSP shortcuts that need an attached server; they error cleanly
    ;; ("no LSP workspace") when there isn't one. `s' (python shell)
    ;; always works.
    (map! :map python-ts-mode-map :localleader
          :desc "python shell"   "s" #'run-python
          :desc "format buffer"  "=" #'lsp-format-buffer
          :desc "code action"    "a" #'lsp-execute-code-action
          :desc "organize imports" "o" #'lsp-organize-imports
          :desc "rename"         "r" #'lsp-rename))
  ;; Debug bindings. Top level so `(modulep! +debug)' resolves while
  ;; `scratch--current-module' is still bound to this module's entry
  ;; (the flag predicate is dynamic).
  (when (and (modulep! +debug) (modulep! :tools dape))
    (with-eval-after-load 'python
      (map! :map python-ts-mode-map :localleader
            (:prefix-map ("d" . "debug")
             :desc "start session"     "d" #'dape
             :desc "toggle breakpoint" "b" #'dape-breakpoint-toggle
             :desc "continue"          "c" #'dape-continue
             :desc "next"              "n" #'dape-next
             :desc "step in"           "s" #'dape-step-in
             :desc "step out"          "o" #'dape-step-out
             :desc "quit session"      "q" #'dape-quit)))))
