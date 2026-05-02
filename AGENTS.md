# AGENTS.md

Guidance for AI agents working on the **scratch** Emacs framework. This is
the repo at `~/.config/emacs-scratch/`. Read top to bottom on first session;
skim later. User-facing docs live in `bin/scratch` (the literate bootstrap
template) and stay in sync with code as features land.

## What this is

`scratch` is a small, Doom-inspired but framework-light Emacs configuration:

- A profile usable side-by-side with Doom via [chemacs2](https://github.com/plexus/chemacs2).
- A module system that mirrors Doom's `:category module` shape with `+flag` support.
- A literate user config in `~/.scratch.d/config.org` that tangles to
  `config.el` + `packages.el`.
- A self-bootstrapping CLI at `bin/scratch` (subcommands: `install`, `sync`).

The framework dir is `~/.config/emacs-scratch/` (this repo). The user dir
defaults to `~/.scratch.d/` (overridable via `$SCRATCHDIR`).

## Repo layout

```
~/.config/emacs-scratch/
  init.el              ; framework dispatcher (loads lisp/, then user dir)
  early-init.el        ; perf knobs (GC defer, native-comp settings, ...)
  custom.el            ; runtime-only; gitignored
  AGENTS.md            ; this file
  bin/scratch          ; CLI + bootstrap template (org source as a string)
  lisp/                ; framework-level topical files (provide 'scratch-X)
    scratch-modules.el ; `scratch!` and `modulep!`
    scratch-keys.el    ; `map!` macro, general.el install, state shorthand
    scratch-window.el  ; native (winum-free) window numbering, M-N bindings
    scratch-buffer.el  ; buffer helpers (kill-others, copy-path, scratch, ...)
    scratch-defaults.el; sensible defaults (savehist, recentf, save-place, ...)
  modules/
    <category>/<name>/
      packages.el      ; eager `straight-use-package` declarations
      config.el        ; configuration
```

The user dir is read first when looking up a module, then the framework dir,
so users can override or shadow any module by mirroring the path under
`$SCRATCHDIR/modules/`.

## Module system

```elisp
(scratch! :editor     (evil +everywhere) leader
          :completion vertico corfu
          :emacs      (vc +forge +gutter)
          :checkers   syntax
          :lang       org
          :os         macos
          :ui         theme modeline fonts treemacs workspaces smooth-scroll)
```

- A keyword (`:editor`) starts a category; symbols/lists after it name modules.
- `(name +flag1 +flag2)` enables flags (must start with `+`).
- All `packages.el` files run first across every enabled module, then all
  `config.el` files. Inside a module's config you can branch on flags:

  ```elisp
  (when (modulep! +forge) ...)         ; current module's flag
  (when (modulep! :editor leader) ...) ; another module is enabled
  (when (modulep! :emacs vc +gutter) ...) ; module + flag
  ```

- **Order matters.** `:editor leader` should come early in `scratch!`
  because producer modules (vc, vertico, treemacs, workspaces, syntax)
  layer their leader bindings on top of leader's defaults via
  last-write-wins. If leader loads after a producer, the producer's
  bindings get clobbered.

## Adding a new module

1. Pick a `:category` and `name`. Reuse Doom's vocabulary when sensible
   (`:ui`, `:emacs`, `:checkers`, `:lang`, `:tools`, ...).
2. Create `modules/<category>/<name>/`.
3. Write `packages.el`. Eagerly install with `straight-use-package`. Gate
   optional installs on flags via `(when (modulep! +flag) ...)`. Always
   include the file header `;;; ... -*- lexical-binding: t; no-byte-compile: t; -*-`.
4. Write `config.el`. Use `use-package` for normal config; reach for raw
   `with-eval-after-load` only when use-package can't express the load
   order. File header: `;;; ... -*- lexical-binding: t; -*-`.
5. **Update `bin/scratch`** to document the new module under
   "Built-in modules" and append it to both example `scratch!` blocks
   (the active one and the commented-out one). The bootstrap template
   lives as a quoted org-mode string inside `scratch-cli--starter-config-org`.
6. If the module persists state to disk, add the relevant ignore patterns
   to `.gitignore`. Anchor patterns that should only match the repo root
   with a leading `/` (e.g. `/workspaces/` to ignore the persp save dir
   without hiding `modules/ui/workspaces/`).
7. Sanity check by byte-compiling with `map!` available (see Testing).

## Bindings: the `map!` macro

`map!` lives in `lisp/scratch-keys.el` and wraps `general-define-key`. Top-level
keywords:

| keyword | meaning |
|---|---|
| `:leader` | bind under leader prefix; auto-applies states + override map |
| `:localleader` | bind under localleader (works at `SPC m KEY` and direct `, KEY`) |
| `:map MAP` | shorthand for `:keymaps MAP` |
| `:mode org` | shorthand for `:keymaps 'org-mode-map` |
| anything else (`:states`, `:after`, ...) | passes through to general |

Body forms:

| form | meaning |
|---|---|
| `:desc DESC` | which-key label for the next KEY/DEF pair |
| `:n` / `:i` / `:v` / `:m` / `:o` / `:e` / `:r` / `:g` | state shorthand (Doom-style); applies to the next KEY/DEF or the next `(:prefix-map ...)` group |
| `:nv`, `:nvm`, ... | combo state shorthand |
| `(:prefix-map (KEY . LABEL) BODY...)` | group bindings under KEY with which-key label |
| `(:prefix KEY ...)` | alternative spelling; nests |

Notes:

- State shorthand is one-shot. Repeat `:n` per binding, or wrap a
  `(:prefix-map ...)` to scope the whole group to those states.
- State shorthand is **not** allowed under `:leader` / `:localleader`. The
  macro raises an error if you try; those forms pin their own `:states`.
- Each module owns its leader submenu (e.g. `:emacs vc` owns `SPC g`,
  `:ui treemacs` owns `SPC o`, `:ui workspaces` owns `SPC l`). Don't
  add bindings for another module's prefix from a different module.

Examples:

```elisp
;; Leader prefix-map (SPC g g, SPC g b, ...)
(map! :leader
  (:prefix-map ("g" . "git")
   :desc "magit status" "g" #'magit-status
   :desc "blame"        "b" #'magit-blame))

;; Mode-map binding with evil state shorthand
(map! :map flycheck-error-list-mode-map
  :n "j" #'flycheck-error-list-next-error
  :n "k" #'flycheck-error-list-previous-error)

;; State-scoped prefix-map
(map! :map foo-mode-map
  :n (:prefix-map ("p" . "project") "x" #'cmd))
```

## Naming conventions

| pattern | use |
|---|---|
| `scratch/foo` | interactive command for users (slash separates namespace from cmd) |
| `scratch-foo` | public variable or non-interactive function |
| `scratch-foo--bar` | internal helper (double-dash prefix) |
| `scratch-MODULE-foo` | module-scoped variable (e.g. `scratch-treemacs-git-mode`) |
| `scratch-MODULE--bar` | module-scoped internal helper |

Hooks defined inside a module follow `scratch-MODULE--name-h` if they're
internal, or named functions when readability matters more than namespace.

## Framework-level helpers (`lisp/scratch-X.el`)

When a feature is needed framework-wide (not gated on a module), add a new
`lisp/scratch-X.el` with `(provide 'scratch-X)` at the bottom and `(require
'scratch-X)` it from `init.el`. Don't pile feature code into existing
files past their topic.

Existing files:

- `scratch-modules.el`: `scratch!`, `modulep!`, module loader.
- `scratch-keys.el`: `map!`, leader / localleader prefix vars,
  state-shorthand machinery (`scratch-keys--state-chars`).
- `scratch-window.el`: `scratch/select-window-by-number`,
  `scratch/buffer-to-window-N`, `scratch/toggle-maximize-window`.
  M-N bound globally via general's override map (state-aware so it wins
  over evil-collection aux maps in magit-section, dired, etc.).
  Numbered list filters out windows with `no-other-window` set, so
  side panels (treemacs) don't take a slot.
- `scratch-buffer.el`: `scratch/switch-to-last-buffer`,
  `scratch/scratch-buffer`, `scratch/kill-other-buffers`,
  `scratch/copy-buffer-filepath`, ...
- `scratch-defaults.el`: file handling (no lockfiles / backups),
  `recentf-mode`, `savehist-mode`, `save-place-mode`, indent / tab defaults.

## The bootstrap template (`bin/scratch`)

`bin/scratch` is a polyglot shell + elisp script. Subcommands:

- `scratch install` writes a starter `~/.scratch.d/config.org` if missing.
- `scratch sync` installs declared packages and re-tangles config.org.

The starter org content lives as a quoted string in the
`scratch-cli--starter-config-org` function. **Treat it as the canonical
user-facing reference.** Whenever a module gains, loses, or renames
features / flags / bindings, update:

1. The module's docs section under "Built-in modules" (`*** :category name`).
2. Both example `scratch!` blocks (active and commented).
3. Override variable lists if any new `defvar` allows user override.

This rule has its own memory (`feedback_scratch_starter_docs.md`) because
silent drift is the most common way the docs go stale.

## Testing & debugging

Don't run interactive Emacs to validate config changes. Two patterns:

**Byte-compile a single module config** (with `map!` and `modulep!` available):

```bash
emacs -Q --batch \
  --eval "(defalias 'straight-use-package 'ignore)" \
  -L /Users/aa646/.config/emacs-scratch/lisp \
  -L /Users/aa646/.config/emacs-scratch/straight/build/general \
  --eval "(require 'cl-lib)" \
  -l general \
  --eval "(defvar scratch-emacs-dir \"/Users/aa646/.config/emacs-scratch/\")" \
  --eval "(defvar scratch-user-dir \"/Users/aa646/.scratch.d/\")" \
  -l /Users/aa646/.config/emacs-scratch/lisp/scratch-modules.el \
  -l /Users/aa646/.config/emacs-scratch/lisp/scratch-keys.el \
  --eval "(defmacro use-package (&rest args) nil)" \
  --eval "(byte-compile-file \"PATH/TO/config.el\")" 2>&1 | grep -E "Error"
```

Warnings about free variables / unknown functions for the module's own
package are normal in this minimal env (the package isn't loaded). Only
errors matter.

**Full daemon run with log inspection**:

```bash
emacs --init-directory /Users/aa646/.config/emacs-scratch/ --daemon=scratch-test 2>&1 | tail -20
emacsclient -s scratch-test --eval "(with-current-buffer \"*Messages*\" (buffer-string))"
emacsclient -s scratch-test --eval "(if (get-buffer \"*Warnings*\") (with-current-buffer \"*Warnings*\" (buffer-string)) \"none\")"
emacsclient -s scratch-test --eval "(kill-emacs)"
```

The headless `auto-dark` "could not determine theme detection mechanism"
notice is benign in daemon mode; it resolves on first GUI frame. Anything
else is real.

For macro-expansion debugging, write a small `/tmp/test-foo.el` that
loads scratch-keys.el and pretty-prints the expansion. Avoid heredoc-ing
elisp into `--eval` since shell quoting bites.

## Established patterns / gotchas

These are load-bearing; preserve them when refactoring.

- **Module ordering in `scratch!`.** `:editor leader` first; producers
  follow. Producer modules' bindings need to be the last word.
- **Each module owns its leader bindings.** Producers call
  `(map! :leader ...)` from their own `config.el`. Don't centralize
  bindings in `:editor leader`'s files past the framework-level basics
  (file / buffer / window / help / quit / project).
- **Defer to evil-collection.** When a package has an evil-collection
  integration, that's the baseline. Add custom keys (`C-j` / `C-k` / etc.)
  only where evil-collection doesn't already cover the spot. Don't
  re-do work it already does.
- **No brute-force overrides.** When a binding loses to a package's
  own keymap (commonly evil-collection's normal-state aux maps), don't
  paper over it with per-package overrides. Find the root cause and fix
  once. The M-N window-select bindings live in general's override-map
  intercept aux maps via `:states '(normal visual ...)` for that reason.
- **Framework topical setup goes in `lisp/scratch-X.el`.** Not piled
  into `init.el`. Each topic gets its own file with `(provide 'scratch-X)`.
- **Bootstrap template stays in sync.** Every feature change updates
  `bin/scratch`'s starter config docs in the same edit.
- **Treemacs is window 0.** `scratch-window--numbered-list` filters
  windows whose `no-other-window` parameter is set. M-0 is bound to
  `treemacs-select-window`; M-1..9 walk the real windows.
- **`global-diff-hl-mode` not per-mode hooks.** When wiring a global
  minor-mode that's autoloaded, hook it on `emacs-startup` directly.
  The autoload pulls the package in; the `:config` block runs as part
  of the load. Don't combine multiple `:hook` keywords with implicit
  `:defer t` plus a separate `(global-foo-mode 1)` in `:config`; the
  ordering gets fragile.
- **persp-mode + project.el bridge.** `:ui workspaces` advises
  `project-switch-project` so opening a project pops you into a
  workspace named after it (recycling an empty current workspace).
- **gitignore anchoring.** Patterns like `workspaces/` (no leading `/`)
  match anywhere in the tree. Anchor with `/workspaces/` if you only
  mean the repo root.

## Style preferences (from user's CLAUDE.md)

- **Never use em dashes** (—). Use commas, periods, colons, semicolons,
  parentheses, or `--` (ASCII double-hyphen) instead. The codebase uses
  `--` consistently in elisp comments; match that.
- **Avoid LLM-flavored words**: "delve", "crucial", "pivotal", "vibrant",
  "tapestry", "landscape" (abstract sense), "showcase", "underscore"
  (verb), "foster", "garner", "enhance", "enduring", "testament",
  "interplay", "intricate", "nestled", "renowned", "groundbreaking"
  (figurative), "serves as", "stands as", "Additionally" (sentence start).
  Plain prose.
- **Don't commit code without asking.** The user oversees commit messages
  and usually commits themselves. Ask before `git commit`.
- **Be direct, ask when in doubt.** Disagree respectfully when a
  proposed change is wrong; don't perform agreement.

## Quick "do I need to..." checklist

- New module → write packages.el + config.el, update bin/scratch docs.
- Cross-module functionality → put in `lisp/scratch-X.el`, require from init.el.
- New leader binding inside an existing module → call `(map! :leader ...)` in that module's config.el.
- New global keybinding (M-something) that needs to win over evil-collection
  aux maps → bind via `general-define-key :states '(normal ...) :keymaps 'override`.
- New persistent file the runtime writes → add to `.gitignore`, anchor
  with `/` if it should only match at the repo root.
- Behavior the user mentions across sessions ("don't" / "always" / "we
  decided") → save to memory under `~/.claude/projects/-Users-aa646--config-emacs-scratch/memory/`.
