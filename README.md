# Scratch Emacs

A light-weight, [Doom](https://github.com/doomemacs/doomemacs)-inspired
Emacs configuration framework. Personal and opinionated, meant to be used
primarliy by my for my own entertainment.

## Why this exists

Doom is great, but it carries a lot of machinery I don't use. `scratch`
is a minimal alternative that keeps the parts I like:

- A module system that mirrors Doom's `:category module +flag` shape.
- The `map!` macro for terse, evil-aware key bindings.
- A leader / localleader workflow that feels like home.
- A literate user config that tangles to elisp.

This is a personal project. It evolves with my own preferences. Use it
as a reference if useful, fork it if you want, but expect breaking
changes at any point.

## Requirements

- **Emacs 29+** (uses `pixel-scroll-precision-mode`, `project.el`
  features, and modern use-package).
- **Git** for package management via [straight.el](https://github.com/radian-software/straight.el).
- **A nerd font** (run `M-x nerd-icons-install-fonts` once on a new
  machine) if you want the modeline and treemacs glyphs.
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg` on PATH)
  for `SPC /` project-wide search via `consult-ripgrep`.
- **`cmake`** and **`libtool`** (macOS: `brew install cmake libtool`)
  for `:term vterm` — vterm builds a native module on first load.

## Install

The repo is the framework. The user config lives elsewhere
(`~/.scratch.d/` by default, overridable via `$SCRATCHDIR`).

### As a side-by-side profile with chemacs2

If you already have another emacs config and want to keep it as the default:

```bash
git clone https://github.com/<you>/emacs-scratch ~/.config/emacs-scratch
~/.config/emacs-scratch/bin/scratch install   # writes ~/.scratch.d/config.org
```

Then in `~/.emacs-profiles.el`:

```elisp
(("default" . ((user-emacs-directory . "~/.config/emacs")))
 ("scratch" . ((user-emacs-directory . "~/.config/emacs-scratch")
               (env . (("SCRATCHDIR" . "~/.scratch.d/"))))))
```

Switch with `CHEMACS_PROFILE=scratch emacs`.

### Standalone

Point `~/.emacs.d` at the framework:

```bash
git clone https://github.com/<you>/emacs-scratch ~/.emacs.d
~/.emacs.d/bin/scratch install
```

### First run

```bash
~/.config/emacs-scratch/bin/scratch sync
```

`sync` installs every package the enabled modules declare and tangles
`config.org` to `config.el` + `packages.el`. Re-run it whenever you
edit `config.org`'s `:tangle packages.el` blocks.

### Reproducible installs

Every installed package is pinned to a specific commit via straight's
versions lockfile at `straight/versions/default.el`, which is tracked
in git. On a fresh clone, `scratch sync` will install at the locked
SHAs; on subsequent startups Emacs thaws to those commits before any
module loads.

When you add a new package to a module's `packages.el`, it clones at
HEAD on first install. Capture the resulting commit into the lockfile:

```bash
~/.config/emacs-scratch/bin/scratch freeze
```

Commit the changed `straight/versions/default.el` alongside the
package addition. Same workflow when you intentionally upgrade a
package: bump the version locally, then `scratch freeze` to record it.

### Shell environment for GUI Emacs

GUI Emacs (Dock / Finder / launchd, also Linux app launchers) doesn't
inherit your shell environment, so `PATH` additions you made in
`.zshrc` / `.zprofile` (Homebrew, `~/.local/bin`, asdf, mise, ...) go
missing. That breaks LSP server lookup, formatters, ripgrep, and so on.

```bash
~/.config/emacs-scratch/bin/scratch env
```

Snapshots the current shell environment to `<emacs-dir>/env`. The file
is loaded by `init.el` before any module so subprocesses inherit the
same `PATH` / `MANPATH` / language-version vars as a terminal-launched
Emacs. Run from the same shell whose env you want captured; re-run
after editing your shell rc files. `scratch env clear` removes it.

The snapshot is filtered through a blocklist (volatile vars: PWD,
SSH sockets, X11/Wayland session IDs, etc.). Override with
`-a/--allow REGEXP` to force-include or `-b/--block REGEXP` to
exclude additional vars.

## What's in the box

The default `(scratch! ...)` call enables these modules. Comment any
you don't want, then run `scratch sync`.

| Category      | Module               | Flags                      | Summary                                                                                                                                                                                                                                                                                                                              |
|---------------|----------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:editor`     | `evil`               | `+everywhere`              | vim emulation + evil-surround / evil-numbers / evil-nerd-commenter / evil-matchit / evil-args + avy                                                                                                                                                                                                                                  |
| `:editor`     | `leader`             | --                         | `SPC` leader, which-key, `general.el`, `map!` macro                                                                                                                                                                                                                                                                                  |
| `:editor`     | `smartparens`        | --                         | structured editing for `()` / `[]` / `{}` / quotes / tags via `smartparens-global-mode` (auto-pair, navigate, slurp/barf)                                                                                                                                                                                                            |
| `:editor`     | `ws-butler`          | --                         | trim trailing whitespace on save, but only on lines you've edited this session                                                                                                                                                                                                                                                       |
| `:editor`     | `drag-stuff`         | --                         | move line / region with `M-↑` / `M-↓`, words with `M-←` / `M-→`                                                                                                                                                                                                                                                                      |
| `:editor`     | `tree-sitter`        | --                         | `treesit-auto` discovers installed grammars and remaps to `<lang>-ts-mode`; pre-computed lang list to keep file-open snappy                                                                                                                                                                                                          |
| `:editor`     | `vlf`                | --                         | very-large-file support (multi-GB files load in chunks); lazy, no overhead until needed                                                                                                                                                                                                                                              |
| `:editor`     | `symbol-overlay`     | --                         | `M-i` highlight every occurrence of symbol at point; `M-n`/`M-p` jump between them                                                                                                                                                                                                                                                   |
| `:editor`     | `outshine`           | --                         | org-style folding / nav in non-org modes (`;;; foo` headings in elisp etc.) via `outline-minor-mode`                                                                                                                                                                                                                                 |
| `:editor`     | `snippets`           | --                         | `yasnippet` + `yasnippet-snippets` (built-in collection); user snippets under `$SCRATCHDIR/snippets/`; `consult-yasnippet` picker (vertico); `SPC i s/S/e/r` leader bindings                                                                                                                                                         |
| `:editor`     | `format`             | --                         | `apheleia` async format-on-save for every buffer with a known formatter (prettier, gofmt, csharpier, mix format, ...); `SPC c f` smart wrapper prefers apheleia → lsp-format → indent-region; per-language modules override individual formatters (csharpier via `dotnet`, mix format from project root, etc.)                       |
| `:completion` | `vertico`            | --                         | vertical minibuffer + orderless + marginalia + consult + embark                                                                                                                                                                                                                                                                      |
| `:completion` | `corfu`              | --                         | in-buffer popup completion + cape + nerd-icons + corfu-terminal                                                                                                                                                                                                                                                                      |
| `:emacs`      | `vc`                 | `+forge`, `+gutter`        | magit + magit-todos, browse-at-remote, git-timemachine, smerge auto-enable; +forge for GH/GL issues+PRs; +gutter for diff-hl                                                                                                                                                                                                         |
| `:emacs`      | `ibuffer`            | --                         | nerd-icons in the buffer column, human-readable sizes, `ibuffer-vc` grouping by VCS root, `hl-line-mode`; `H` toggles `*`-prefixed buffers, `C-j`/`C-k` group nav, `$` toggle group                                                                                                                                                  |
| `:emacs`      | `dired`              | --                         | `dired-dwim-target`, recursive copies/deletes, `dired-async-mode`, `dired-hide-dotfiles` (`H`), `dired-recent` (`r`), `nerd-icons-dired`, `gls` fallback on macOS, tar.gz/bz2/xz/zst compress alist; `SPC -` `dired-jump`; `h`/`l` evil up/enter, `G` `consult-dir`, `K` kill-lines                                                  |
| `:checkers`   | `syntax`             | --                         | `flycheck` global + `flycheck-posframe` tooltips; uses `consult-flycheck` when vertico is enabled                                                                                                                                                                                                                                    |
| `:lang`       | `org`                | `+roam`                    | `org-modern` + `org-appear` + `org-cliplink` + `org-download`, scaled headings, hidden emphasis markers; +roam adds org-roam                                                                                                                                                                                                         |
| `:lang`       | `markdown`           | --                         | `markdown-mode` with native code-block highlighting + scaled headings; tables / pre / HRs stay fixed-pitch in mixed-pitch                                                                                                                                                                                                            |
| `:lang`       | `csharp`             | --                         | `csharp-ts-mode` for `.cs` (when grammar is installed; falls back to `csharp-mode`), `dotnet` build/run/test minor mode + `,` localleader, `.csproj`/`.props`/`.targets` as XML; project-local `csharp-ls` auto-detected; auto-LSP via `:tools lsp`                                                                                  |
| `:lang`       | `elixir`             | --                         | `elixir-ts-mode` / `heex-ts-mode`, `exunit` test-runner localleader (`,t a/r/v/s/T/t`), `dexter` LSP client (priority 2; expects `dexter` on PATH), `lsp-credo` add-on for live credo, `flycheck-credo` + `flycheck-dialyxir` (chained after `lsp` checker), `_build`/`deps`/`.elixir_ls`/`.expert` file-watch ignores               |
| `:tools`      | `lsp`                | `+peek`                    | `lsp-mode` + `lsp-ui` + `consult-lsp` (vertico) + `lsp-treemacs` (treemacs); `scratch-lsp-auto-modes` auto-attaches per language; `SPC c` bindings; performance tuned: 1 MB read buffer, 64 MB GC during sessions, deferred shutdown, no JSON-RPC log, raised file-watch threshold; `+peek` routes `c d/D/i/S` through `lsp-ui-peek` |
| `:tools`      | `direnv`             | --                         | `envrc.el` (purcell) buffer-local hook into the `direnv` CLI; reads `.envrc` per project so subprocesses (LSP, compile, vterm) inherit project env. Pairs with `mise`. Needs `direnv` on PATH                                                                                                                                        |
| `:tools`      | `mise`               | --                         | `mise.el` (eki3z) buffer-local hook into the `mise` CLI; reads `mise.toml` / `.tool-versions` so subprocesses get the project's pinned `node` / `python` / etc. Pairs with `direnv`. Needs `mise` on PATH                                                                                                                            |
| `:term`       | `vterm`              | --                         | libvterm-backed terminal; project-aware `SPC o t` toggle popup + `SPC o T` here; needs `cmake` + `libtool` + `libvterm`                                                                                                                                                                                                              |
| `:os`         | `macos`              | --                         | undecorated frame, `Cmd-=/-/0` text scale, native pop-up handling                                                                                                                                                                                                                                                                    |
| `:ui`         | `theme`              | `+auto`, `+light`, `+dark` | modus-themes; +auto follows OS appearance via `auto-dark`                                                                                                                                                                                                                                                                            |
| `:ui`         | `modeline`           | --                         | doom-modeline with theme-aware refresh                                                                                                                                                                                                                                                                                               |
| `:ui`         | `fonts`              | --                         | sane default heights for default / fixed-pitch / variable-pitch + `mixed-pitch-mode` in prose buffers                                                                                                                                                                                                                                |
| `:ui`         | `treemacs`           | --                         | side-pane file tree (also brings nerd-icons into dired); auto-integrates with vc / workspaces / lsp                                                                                                                                                                                                                                  |
| `:ui`         | `workspaces`         | --                         | named buffer sets via persp-mode; auto-creates per-project workspace                                                                                                                                                                                                                                                                 |
| `:ui`         | `smooth-scroll`      | `+interpolate`             | pixel-precise wheel scrolling via ultra-scroll; +interpolate adds keyboard smoothing                                                                                                                                                                                                                                                 |
| `:ui`         | `hl-todo`            | --                         | highlight TODO / FIXME / NOTE / HACK / etc.; `consult-todo` picker when vertico is on                                                                                                                                                                                                                                                |
| `:ui`         | `info-colors`        | --                         | colorize headings / refs / keys in Info manual pages                                                                                                                                                                                                                                                                                 |
| `:ui`         | `rainbow`            | --                         | `rainbow-mode` paints CSS color literals (`#ff7f50` etc.) with their actual color in CSS / web / lisp / conf buffers                                                                                                                                                                                                                 |
| `:ui`         | `default-text-scale` | --                         | `C-M-=` / `C-M--` / `C-M-0` zooms every buffer in lockstep (cross-platform; `:os macos` already binds per-buffer Cmd-=)                                                                                                                                                                                                              |

Full feature docs and override variables for each module live in
`bin/scratch` (the literate bootstrap template, copied to
`~/.scratch.d/config.org` on `scratch install`).

## Customization

Open `~/.scratch.d/config.org` in Emacs and edit. Three blocks matter:

```org
* Packages

#+begin_src emacs-lisp :tangle packages.el
(scratch! :editor     (evil +everywhere) leader smartparens
                      ws-butler drag-stuff tree-sitter vlf
                      symbol-overlay outshine snippets
          :completion vertico corfu
          :emacs      (vc +forge +gutter)
          :checkers   syntax
          :tools      lsp
          :lang       org markdown csharp
          :os         macos
          :ui         theme modeline fonts treemacs workspaces smooth-scroll hl-todo info-colors rainbow default-text-scale)
#+end_src
```

Add/remove modules and flags here. Producer modules (vc, vertico,
treemacs, workspaces, ...) layer their leader bindings on top of
`:editor leader`'s baselines, so list `:editor (... leader)` near the
top.

```org
* Configuration

#+begin_src emacs-lisp
;; Override module variables BEFORE scratch! runs (see bin/scratch
;; for the full list).
(setq scratch-projects-search-path '("~/code" "~/work")
      scratch-theme-dark           'modus-vivendi-tinted
      scratch-font-height          150)
#+end_src
```

Anything in the regular config.el block runs after every module loads,
so it's the last word.

After editing the org file, `scratch sync` re-tangles + installs new
packages. Tangle alone happens on Emacs startup if the org file is
newer than the tangled outputs.

## Themes

`:ui theme` ships [modus-themes](https://protesilaos.com/emacs/modus-themes)
(`modus-vivendi` dark, `modus-operandi` light), wrapped in a flag for
how to switch between them:

| flag             | effect                                         |
|------------------|------------------------------------------------|
| (none) / `+auto` | follow OS appearance via `auto-dark` (default) |
| `+light`         | force light                                    |
| `+dark`          | force dark                                     |

Swap in any other theme package by installing it eagerly in
`packages.el` and overriding `scratch-theme-dark` /
`scratch-theme-light` BEFORE `(scratch! ...)` runs:

```org
* Packages

#+begin_src emacs-lisp :tangle packages.el
;; Install the theme package eagerly so its symbols are loadable
;; by the time the :ui theme module activates them.
(straight-use-package 'doom-themes)

(setq scratch-theme-dark  'doom-one
      scratch-theme-light 'doom-one-light)

(scratch! :editor (evil +everywhere) leader
          ;; ... rest of your modules ...
          :ui     theme modeline fonts treemacs workspaces smooth-scroll hl-todo info-colors rainbow default-text-scale)
#+end_src
```

Both variants of the variable are theme symbols (the same value you'd
pass to `M-x load-theme`). The framework loads exactly one at a time
and disables the previous theme on switch, so `+auto` (the default)
flips between the two cleanly when the OS appearance changes.

To use a single theme regardless of OS appearance, set both variables
to the same symbol and add `+light` or `+dark` to pin which one
counts:

```elisp
(setq scratch-theme-dark  'ef-dark
      scratch-theme-light 'ef-dark)
(scratch! ... :ui (theme +dark) ...)
```

Then `scratch sync` (to install the new theme package) and restart Emacs.

## Key paths and how to change them

| Variable                             | Default   | Purpose                               |
|--------------------------------------|-----------|---------------------------------------|
| `scratch-leader-key`                 | `"SPC"`   | leader prefix in normal/visual/motion |
| `scratch-leader-non-normal-key`      | `"M-SPC"` | leader prefix in insert/emacs         |
| `scratch-localleader-key`            | `","`     | localleader in normal/visual/motion   |
| `scratch-localleader-non-normal-key` | `"M-,"`   | localleader in insert/emacs           |

Set these before the `(scratch! ...)` call to take effect.

## Default leader bindings

A flavor (full list in `bin/scratch`):

| Key                     | Action                                                           |
|-------------------------|------------------------------------------------------------------|
| `SPC SPC`, `SPC :`      | `M-x`                                                            |
| `SPC .`                 | find file                                                        |
| `SPC ,`                 | switch buffer (workspace-restricted when `:ui workspaces` is on) |
| `SPC /`                 | project-wide search (consult-ripgrep, requires `rg`)             |
| `SPC a`                 | embark act on candidate / thing at point (also `C-.` globally)   |
| `SPC TAB`               | last buffer                                                      |
| `SPC b b/N/k/r/...`     | buffer ops                                                       |
| `SPC f f/r/s/...`       | file ops                                                         |
| `SPC w h/j/k/l/m/...`   | window navigation, maximize toggle                               |
| `SPC p p/f/b/D/A/...`   | project ops + projectile-style discovery layer                   |
| `SPC g g/d/l/L/b/h/...` | git (magit, browse-at-remote, hunk submenu)                      |
| `SPC h f/v/k/...`       | help                                                             |
| `SPC c c/C`             | compile / recompile                                              |
| `SPC c d/D/i/t/k/K`     | jump to def / refs / impl / type def / describe / ui-doc popup   |
| `SPC c a/r/o`           | code action / rename / organize imports (lsp)                    |
| `SPC c f/F/w/W`         | format buffer / region / trim trailing ws / trim trailing nl     |
| `SPC c j/J/s/X`         | workspace symbols / all-workspaces / file symbols / diagnostics  |
| `SPC c l ...`           | full lsp-command-map (workspaces / folders / toggles / peeks)    |
| `SPC c x/n/p/e`         | flycheck list / next / prev / explain                            |
| `SPC l l/./n/r/d/...`   | workspace                                                        |
| `SPC o p/P`             | open project tree (treemacs)                                     |
| `SPC s ...`             | consult search commands                                          |
| `SPC q q/Q`             | quit                                                             |

Plus `M-1` ... `M-9` for native window numbering, `M-0` for the treemacs side panel.

Evil-side niceties beyond stock evil:

| Key                      | Action                                                                       |
|--------------------------|------------------------------------------------------------------------------|
| `gc` / `gcc`             | comment operator (motion / current line) -- `gc{motion}`, visual `gc`        |
| `g=` / `g-`              | increment / decrement number at point (visual variants count up)             |
| `gs s` / `gs SPC`        | avy: jump to 2-char location / type chars until timer fires                  |
| `gs c` / `gs l` / `gs w` | avy: jump to char / line / word starting with char                           |
| `%`                      | language-aware jump between matching pair (parens, tags, function start/end) |
| `ys`/`cs`/`ds`           | add / change / delete a surround pair                                        |
| `cia` / `caa`            | change inside / around the function-argument under point                     |
| `SPC s t` / `SPC s T`    | TODO/FIXME picker (current buffer / project) via consult-todo                |

## Differences from Doom

- **No autoload generation.** The module loader just loads `packages.el`
  then `config.el` per module, in declaration order. Functions are
  reachable when their package loads.
- **No popup management system.** A small `display-buffer-alist`
  default selects useful temp windows (Process List, Buffer List,
  Occur, Async Shell Command); add to it as needed.
- **Built-in `project.el` instead of `projectile`.** Projectile-style
  search-path / discover / cleanup commands are implemented as a thin
  layer over project.el (`SPC p D`, `SPC p C`, `SPC p A`, ...).
- **Native window numbering instead of `winum`.** See
  `lisp/scratch-window.el`.
- **Smaller surface area.** Around 500 lines of framework code; modules
  are mostly thin wrappers over upstream packages.

## Layout

```
~/.config/emacs-scratch/
  init.el              ; framework entry point
  early-init.el        ; performance knobs
  bin/scratch          ; CLI + bootstrap template
  AGENTS.md            ; guidance for AI agents working on the framework
  lisp/                ; framework-level topical files
  modules/<category>/<name>/
    packages.el        ; eager package declarations
    config.el          ; configuration

~/.scratch.d/          ; user dir (override via $SCRATCHDIR)
  config.org           ; literate config; tangles to:
  config.el            ; (auto-generated)
  packages.el          ; (auto-generated)
```

## Acknowledgements

Heavily inspired by [Doom Emacs](https://github.com/doomemacs/doomemacs).
Several modules are direct adaptations of Doom's, trimmed of Doom-specific
helpers. Where a particular pattern is recognisable as Doom's, it is.

The bedrock packages do all the real work:
[straight.el](https://github.com/radian-software/straight.el),
[use-package](https://github.com/jwiegley/use-package),
[general.el](https://github.com/noctuid/general.el),
[evil](https://github.com/emacs-evil/evil),
[evil-collection](https://github.com/emacs-evil/evil-collection),
[vertico](https://github.com/minad/vertico),
[corfu](https://github.com/minad/corfu),
[consult](https://github.com/minad/consult),
[orderless](https://github.com/oantolin/orderless),
[marginalia](https://github.com/minad/marginalia),
[magit](https://github.com/magit/magit),
[doom-modeline](https://github.com/seagle0128/doom-modeline),
[treemacs](https://github.com/Alexander-Miller/treemacs),
[persp-mode](https://github.com/Bad-ptr/persp-mode.el),
[ultra-scroll](https://github.com/jdtsmith/ultra-scroll),
[diff-hl](https://github.com/dgutov/diff-hl),
[flycheck](https://www.flycheck.org),
[hl-todo](https://github.com/tarsius/hl-todo).
