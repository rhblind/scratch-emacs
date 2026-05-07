# Modules

All modules are opt-in via the `scratch!` macro. Each one has a
`packages.el` (what to install) and a `config.el` (how to configure
it). Flags like `+everywhere` toggle optional features within a
module.

## `:editor` -- editing behaviour

Core editing enhancements: modal editing, keybindings, structural
editing, formatting. These shape how you interact with text across
all modes.

| Module           | Flags           | Summary                                            |
|------------------|-----------------|----------------------------------------------------|
| `evil`           | `+everywhere`   | Vim emulation + surround, matchit, numbers, avy    |
| `leader`         |                 | SPC leader, which-key, general.el, `map!` macro    |
| `smartparens`    |                 | Auto-pair, navigate, slurp/barf                    |
| `ws-butler`      |                 | Trim trailing whitespace on edited lines only      |
| `drag-stuff`     |                 | Move lines/regions with M-arrows                   |
| `tree-sitter`    |                 | Auto-remap to `*-ts-mode` via treesit-auto         |
| `vlf`            |                 | Multi-GB file support (chunked loading)            |
| `symbol-overlay` |                 | Highlight + navigate symbol at point               |
| `outline`        |                 | Heading folding/cycling via outline-minor-mode     |
| `snippets`       |                 | Yasnippet + consult picker                         |
| `format`         |                 | Apheleia format-on-save, `SPC c f` smart formatter |

## `:completion` -- finding and selecting things

Minibuffer and in-buffer completion. These two modules work together
but can be enabled independently.

| Module   | Flags | Summary                                            |
|----------|-------|----------------------------------------------------|
| `vertico`|       | Vertical minibuffer + orderless + consult + embark  |
| `corfu`  |       | In-buffer popup completion + cape                   |

## `:emacs` -- built-in Emacs features, enhanced

Wrappers around core Emacs functionality that add better defaults,
keybindings, and integrations.

| Module    | Flags              | Summary                                            |
|-----------|--------------------|----------------------------------------------------|
| `vc`      | `+forge`, `+gutter`| Magit, browse-at-remote, git-timemachine, diff-hl   |
| `ibuffer` |                    | Enhanced buffer list with VC grouping               |
| `dired`   |                    | File manager with async ops, nerd-icons, dotfiles   |

## `:checkers` -- on-the-fly diagnostics

Live feedback while you edit.

| Module   | Flags | Summary                              |
|----------|-------|--------------------------------------|
| `syntax` |       | Flycheck + posframe tooltips         |

## `:tools` -- development tooling

Language-agnostic tools that `:lang` modules build on.

| Module   | Flags   | Summary                                      |
|----------|---------|----------------------------------------------|
| `lsp`    | `+peek` | lsp-mode + lsp-ui + consult-lsp, perf-tuned  |
| `direnv` |         | Buffer-local direnv via envrc.el              |
| `mise`   |         | Buffer-local mise for runtime versions        |
| `just`   |         | Major mode for Justfiles via just-mode         |

## `:lang` -- language support

Per-language modes, LSP wiring, and companion tooling. Most default
to tree-sitter major modes when a grammar is available.

| Module     | Flags   | Summary                                          |
|------------|---------|--------------------------------------------------|
| `org`      | `+roam` | org-modern, org-appear, org-cliplink; +roam       |
| `markdown` |         | markdown-mode with native code-block highlighting |
| `csharp`   |         | csharp-ts-mode, dotnet minor mode, csharp-ls      |
| `elixir`   |         | elixir-ts-mode, exunit runner, LSP via lexical    |
| `json`     |         | json-ts-mode, auto-LSP                            |
| `yaml`     |         | yaml-ts-mode, auto-LSP                            |

## `:term` -- terminal emulators

| Module  | Flags | Summary                           |
|---------|-------|-----------------------------------|
| `vterm` |       | libvterm terminal, `SPC o t` toggle|

## `:os` -- operating system integration

| Module  | Flags | Summary                               |
|---------|-------|---------------------------------------|
| `macos` |       | Undecorated frame, Cmd key bindings   |

## `:ui` -- appearance and layout

Visual tweaks, themes, and window management. None of these change
editing behaviour; they control how things look and where they appear.

| Module              | Flags                      | Summary                                     |
|---------------------|----------------------------|---------------------------------------------|
| `dashboard`         |                            | Startup dashboard                            |
| `theme`             | `+auto`, `+light`, `+dark` | Theme switching; +auto follows OS appearance |
| `modeline`          |                            | doom-modeline                                |
| `fonts`             |                            | Default/fixed/variable-pitch + mixed-pitch   |
| `treemacs`          |                            | Side-pane file tree, integrates with vc/lsp  |
| `workspaces`        |                            | Named buffer sets via persp-mode             |
| `smooth-scroll`     | `+interpolate`             | Pixel-precise scrolling via ultra-scroll     |
| `hl-todo`           |                            | Highlight TODO/FIXME/HACK + consult picker   |
| `info-colors`       |                            | Colorize Info manual pages                   |
| `rainbow`           |                            | Paint CSS color literals with their color    |
| `default-text-scale`|                            | Global text size with C-M-=/C-M--/C-M-0      |
