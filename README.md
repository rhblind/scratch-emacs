# Scratch Emacs

A lightweight, [Doom](https://github.com/doomemacs/doomemacs)-inspired
Emacs configuration framework. Personal and opinionated, meant to be
used primarily by me for my own entertainment.

## Requirements

- **Emacs 30+**
- **Git** for package management via [straight.el](https://github.com/radian-software/straight.el)
- **A nerd font** (`M-x nerd-icons-install-fonts` on first install)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** for `SPC /` project search
- **cmake + libtool** for `:term vterm` (builds a native module on first load)
- **[cmark-gfm](https://github.com/github/cmark-gfm)** (optional) for `:lang markdown` live preview (`brew install cmark-gfm`)

## Install

The repo is the framework. User config lives in `~/.scratch.d/`
(override via `$SCRATCHDIR`).

```bash
# Clone
git clone https://github.com/<you>/emacs-scratch ~/.config/emacs-scratch

# Bootstrap user config
~/.config/emacs-scratch/bin/scratch install

# Install packages + tangle config.org
~/.config/emacs-scratch/bin/scratch sync
```

For side-by-side use with [chemacs2](https://github.com/plexus/chemacs2),
add to `~/.emacs-profiles.el`:

```elisp
(("default" . ((user-emacs-directory . "~/.config/emacs")))
 ("scratch" . ((user-emacs-directory . "~/.config/emacs-scratch")
               (env . (("SCRATCHDIR" . "~/.scratch.d/"))))))
```

### Shell environment for GUI Emacs

GUI Emacs doesn't inherit your shell environment. Snapshot it with:

```bash
~/.config/emacs-scratch/bin/scratch env
```

Re-run after editing shell rc files. `scratch env clear` removes it.

### Reproducible installs

Packages are pinned via `straight/versions/default.el`. After adding
or upgrading a package, run `scratch freeze` and commit the lockfile.

## Modules

See [modules/README.md](modules/README.md) for the full list.

## Customization

Edit `~/.scratch.d/config.org`. Two sections matter:

**Modules** (tangled to `packages.el`): the `scratch!` call declares
which modules to load. Add/remove modules and flags here, then run
`scratch sync`.

**Configuration** (tangled to `config.el`): runs after all modules
load. Override variables, add hooks, install extra packages.

Saving `config.org` in Emacs re-tangles automatically. If edited
externally, run `scratch sync` or Emacs will nudge on next start.

### Themes

`:ui theme` defaults to modus-themes with `+auto` (follows OS
appearance). Override by installing a theme package and setting
`scratch-theme-dark` / `scratch-theme-light` before `scratch!`:

```elisp
(straight-use-package 'doom-themes)
(setq scratch-theme-dark  'doom-nord
      scratch-theme-light 'doom-tomorrow-day)
```

### Leader keys

| Variable                        | Default   |
|---------------------------------|-----------|
| `scratch-leader-key`            | `SPC`     |
| `scratch-leader-non-normal-key` | `M-SPC`   |
| `scratch-localleader-key`       | `,`       |

Set before `scratch!` to take effect. Run `SPC` and which-key shows
the full menu.

## Layout

```
~/.config/emacs-scratch/
  init.el                          framework entry point
  early-init.el                    performance knobs
  bin/scratch                      CLI + bootstrap template
  lisp/                            framework-level elisp
  modules/<category>/<name>/
    packages.el                    package declarations
    config.el                      configuration

~/.scratch.d/                      user dir ($SCRATCHDIR)
  config.org                       literate config (tangles to config.el + packages.el)
```

## Acknowledgements

Heavily inspired by [Doom Emacs](https://github.com/doomemacs/doomemacs).
Several modules are direct adaptations of Doom's, trimmed of
Doom-specific helpers.
