<div align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/d/df/GNU.svg?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=original" height="124px">
  <h1 align="center">Scratch Emacs</h1>
</div>

<p align="center">
A personal and opinionated Emacs framework born out of config bankruptcy.
</p>

Scratch is a small [Doom](https://github.com/doomemacs/doomemacs) inspired configuration
framework with fewer and deliberately chosen packages.

What comes in the box reflects what I actually use day to day and may change at any time.
You're welcome to use it as-is, fork it, or send PRs, but this is mostly  a personal project and comes with no guarantees.

## Requirements

- **Emacs 30+**
- **Git** for package management via [straight.el](https://github.com/radian-software/straight.el)
- **A nerd font** (`M-x nerd-icons-install-fonts` on first install)
- **Tree-sitter grammars** (`M-x treesit-auto-install-all` after enabling a new language module)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** for project search
- **cmake + libtool** for `:term vterm` (builds a native module on first load)
- **[cmark-gfm](https://github.com/github/cmark-gfm)**  for `:lang markdown` live preview

## Install

Clone the repo as your Emacs directory and run the bootstrap:

```bash
git clone https://github.com/rhblind/scratch-emacs.git ~/.config/emacs
~/.config/emacs/bin/scratch install
~/.config/emacs/bin/scratch sync
```

> [!TIP]
> It's a good idea to add `~/.config/emacs/bin/scratch` to your `PATH` so that it's easy to run it from anywhere.

| Command           | Description                                                                            |
|-------------------|----------------------------------------------------------------------------------------|
| `scratch install` | Bootstrap `~/.scratch.d/` with a starter `config.org`. This is your personal config.   |
| `scratch sync`    | Install or purges packages and tangle `config.org` into elisp files for the framework. |
| `scratch upgrade` | Pull the framework, validate your config against it, and sync.                         |
| `scratch freeze`  | Pin packages to `~/.scratch.d/straight-lock.el` for reproducible builds.               |
| `scratch env`     | Snapshot shell environment for Emacs. Re-run after editing shell rc files.              |
| `scratch help`    | Show available commands and options.                                                    |

After adding or upgrading a package, run `scratch freeze` and commit
the lockfile for reproducible installs.

## Modules

Modules live under `modules/<category>/<name>/` in the framework.
Each module has a `packages.el` (package declarations) and a
`config.el` (configuration). No module loads unless you opt in via the
`scratch!` macro in your `config.org`:

```elisp
(scratch! :editor      (evil +everywhere) leader smartparens
          :completion  vertico corfu
          :emacs       (vc +forge +gutter) ibuffer dired
          :checkers    syntax
          :tools       (lsp +peek) editorconfig direnv mise
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

The framework and your personal config are kept in separate
directories. The framework directory is a git clone you can pull or
reset without losing your settings. The user directory holds your
personal config and is the one you version-control.

```
~/.config/emacs/
  init.el                    framework entry point
  early-init.el              performance knobs
  bin/scratch                CLI
  lisp/                      framework-level elisp
  modules/<category>/<name>/
    packages.el              package declarations
    config.el                configuration

~/.scratch.d/                user dir ($SCRATCHDIR)
  config.org                 literate config (tangles to config.el + packages.el)
```
