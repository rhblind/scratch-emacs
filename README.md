# Scratch Emacs

A personal Emacs framework born out of config bankruptcy. I love
[Doom Emacs](https://github.com/doomemacs/doomemacs) but wanted a
smaller codebase I can fully understand, with deliberate choices
instead of inherited ones. Several modules are direct adaptations of
Doom's, trimmed of Doom-specific helpers.

Defaults reflect what I actually use day to day and may change at any
time. You're welcome to use it as-is, fork it, or send PRs, but this
is a personal project and comes with no guarantees.

## Requirements

- **Emacs 30+**
- **Git** for package management via [straight.el](https://github.com/radian-software/straight.el)
- **A nerd font** (`M-x nerd-icons-install-fonts` on first install)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** for `SPC /` project search
- **cmake + libtool** for `:term vterm` (builds a native module on first load)
- **[cmark-gfm](https://github.com/github/cmark-gfm)** (optional) for `:lang markdown` live preview

## Install

The repo is the framework. User config lives separately in
`~/.scratch.d/` (the "user dir"). Set the `$SCRATCHDIR` environment
variable to use a different path. This is the directory you put in
version control.

```bash
git clone https://github.com/<you>/emacs-scratch ~/.config/emacs-scratch
~/.config/emacs-scratch/bin/scratch install   # bootstrap user config
~/.config/emacs-scratch/bin/scratch sync      # install packages + tangle config.org
```

GUI Emacs doesn't inherit your shell environment; run `scratch env` to
snapshot it (re-run after editing shell rc files).

## The `scratch` CLI

The `bin/scratch` script handles everything outside the editor:
bootstrapping, syncing packages, pinning versions, and capturing the
shell environment. Modelled after Doom's `bin/doom`, stripped down to
the commands that matter here.

| Command          | Description                                           |
|------------------|-------------------------------------------------------|
| `scratch install`| Bootstrap `~/.scratch.d/` with a starter `config.org` |
| `scratch sync`   | Install packages and tangle `config.org`              |
| `scratch freeze` | Pin packages to `~/.scratch.d/straight-lock.el`       |
| `scratch env`    | Snapshot shell environment for GUI Emacs               |

After adding or upgrading a package, run `scratch freeze` and commit
the lockfile for reproducible installs.

## Modules

Modules live under `modules/<category>/<name>/` in the framework.
Each module has a `packages.el` (package declarations) and a
`config.el` (configuration). No module loads unless you opt in via the
`scratch!` macro in your `config.org`:

```elisp
(scratch! :editor     (evil +everywhere) leader smartparens
         :completion  vertico corfu
         :emacs       (vc +forge +gutter) ibuffer dired
         :checkers    syntax
         :tools       (lsp +peek) direnv mise
         :lang        org markdown json yaml
         :term        vterm
         :os          macos
         :ui          theme modeline fonts treemacs workspaces)
```

Flags (like `+everywhere`, `+forge`) toggle optional features within a
module. Without `scratch!` you get a bare Emacs with only the
early-init performance knobs.

See [modules/README.md](modules/README.md) for the full list and
per-module documentation.

## Customization

Configuration is literate: you edit a single `~/.scratch.d/config.org`
file that tangles into the elisp files the framework loads. This keeps
rationale next to the code and makes `scratch sync` the single entry
point for applying changes. Two sections matter:

- **Modules** (tangled to `packages.el`): the `scratch!` call declares
  which modules to load. Add/remove modules and flags here, then run
  `scratch sync`.
- **Configuration** (tangled to `config.el`): runs after all modules
  load. Override variables, add hooks, install extra packages.

Saving `config.org` in Emacs re-tangles automatically. If edited
externally, run `scratch sync` or Emacs will nudge on next start.

Themes default to modus-themes with `+auto` (follows OS appearance).
Override with `scratch-theme-dark` / `scratch-theme-light`. Leader
keys (`SPC`, `M-SPC`, `,`) can be changed via `scratch-leader-key`,
`scratch-leader-non-normal-key`, and `scratch-localleader-key`. Set
all of these before the `scratch!` call.

## Layout

```
~/.config/emacs-scratch/
  init.el                   framework entry point
  early-init.el             performance knobs
  bin/scratch                CLI
  lisp/                      framework-level elisp
  modules/<category>/<name>/
    packages.el              package declarations
    config.el                configuration

~/.scratch.d/                user dir ($SCRATCHDIR)
  config.org                 literate config (tangles to config.el + packages.el)
```
