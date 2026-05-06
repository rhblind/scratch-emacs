# Modules

| Category      | Module               | Flags                      | Summary                                            |
|---------------|----------------------|----------------------------|----------------------------------------------------|
| `:editor`     | `evil`               | `+everywhere`              | Vim emulation + surround, matchit, numbers, avy    |
| `:editor`     | `leader`             |                            | SPC leader, which-key, general.el, `map!` macro    |
| `:editor`     | `smartparens`        |                            | Auto-pair, navigate, slurp/barf                    |
| `:editor`     | `ws-butler`          |                            | Trim trailing whitespace on edited lines only      |
| `:editor`     | `drag-stuff`         |                            | Move lines/regions with M-arrows                   |
| `:editor`     | `tree-sitter`        |                            | Auto-remap to `*-ts-mode` via treesit-auto         |
| `:editor`     | `vlf`                |                            | Multi-GB file support (chunked loading)            |
| `:editor`     | `symbol-overlay`     |                            | Highlight + navigate symbol at point               |
| `:editor`     | `outline`            |                            | Heading folding/cycling via outline-minor-mode     |
| `:editor`     | `snippets`           |                            | Yasnippet + consult picker                         |
| `:editor`     | `format`             |                            | Apheleia format-on-save, `SPC c f` smart formatter |
| `:completion` | `vertico`            |                            | Vertical minibuffer + orderless + consult + embark |
| `:completion` | `corfu`              |                            | In-buffer popup completion + cape                  |
| `:emacs`      | `vc`                 | `+forge`, `+gutter`        | Magit, browse-at-remote, git-timemachine, diff-hl  |
| `:emacs`      | `ibuffer`            |                            | Enhanced buffer list with VC grouping              |
| `:emacs`      | `dired`              |                            | File manager with async ops, nerd-icons, dotfiles  |
| `:checkers`   | `syntax`             |                            | Flycheck + posframe tooltips                       |
| `:lang`       | `org`                | `+roam`                    | org-modern, org-appear, org-cliplink; +roam        |
| `:lang`       | `markdown`           |                            | markdown-mode with native code-block highlighting  |
| `:lang`       | `csharp`             |                            | csharp-ts-mode, dotnet minor mode, csharp-ls       |
| `:lang`       | `elixir`             |                            | elixir-ts-mode, exunit runner, LSP via lexical     |
| `:lang`       | `json`               |                            | json-ts-mode, auto-LSP                             |
| `:lang`       | `yaml`               |                            | yaml-ts-mode, auto-LSP                             |
| `:tools`      | `lsp`                | `+peek`                    | lsp-mode + lsp-ui + consult-lsp, perf-tuned        |
| `:tools`      | `direnv`             |                            | Buffer-local direnv via envrc.el                   |
| `:tools`      | `mise`               |                            | Buffer-local mise for runtime versions             |
| `:term`       | `vterm`              |                            | libvterm terminal, `SPC o t` toggle                |
| `:os`         | `macos`              |                            | Undecorated frame, Cmd key bindings                |
| `:ui`         | `dashboard`          |                            | Startup dashboard                                  |
| `:ui`         | `theme`              | `+auto`, `+light`, `+dark` | Theme switching; +auto follows OS appearance       |
| `:ui`         | `modeline`           |                            | doom-modeline                                      |
| `:ui`         | `fonts`              |                            | Default/fixed/variable-pitch + mixed-pitch         |
| `:ui`         | `treemacs`           |                            | Side-pane file tree, integrates with vc/lsp        |
| `:ui`         | `workspaces`         |                            | Named buffer sets via persp-mode                   |
| `:ui`         | `smooth-scroll`      | `+interpolate`             | Pixel-precise scrolling via ultra-scroll           |
| `:ui`         | `hl-todo`            |                            | Highlight TODO/FIXME/HACK + consult picker         |
| `:ui`         | `info-colors`        |                            | Colorize Info manual pages                         |
| `:ui`         | `rainbow`            |                            | Paint CSS color literals with their color          |
| `:ui`         | `default-text-scale` |                            | Global text size with C-M-=/C-M--/C-M-0            |
