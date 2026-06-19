# Modules

All modules are opt-in via the `scratch!` macro. Each one has a
`packages.el` (what to install) and a `config.el` (how to configure
it). Flags like `+everywhere` toggle optional features within a
module.

- [`:editor`](#editor----editing-behaviour) - editing behaviour
- [`:completion`](#completion----finding-and-selecting-things) - finding and selecting things
- [`:emacs`](#emacs----built-in-emacs-features-enhanced) - built-in Emacs features, enhanced
- [`:checkers`](#checkers----on-the-fly-diagnostics) - on-the-fly diagnostics
- [`:tools`](#tools----development-tooling) - development tooling
- [`:lang`](#lang----language-support) - language support
- [`:term`](#term----terminal-emulators) - terminal emulators
- [`:llm`](#llm----ai-assistants) - AI assistants
- [`:os`](#os----operating-system-integration) - operating system integration
- [`:ui`](#ui----appearance-and-layout) - appearance and layout

## `:editor` -- editing behaviour

Core editing enhancements: modal editing, keybindings, structural
editing, formatting. These shape how you interact with text across
all modes.

| Module           | Flags         | Summary                                            |
|------------------|---------------|----------------------------------------------------|
| `evil`           | `+everywhere` | Vim emulation + surround, matchit, numbers, avy    |
| `leader`         |               | SPC leader, which-key, general.el, `map!` macro    |
| `smartparens`    |               | Auto-pair, navigate, slurp/barf                    |
| `ws-butler`      |               | Trim trailing whitespace on edited lines only      |
| `drag-stuff`     |               | Move lines/regions with M-arrows                   |
| `tree-sitter`    |               | Auto-remap to `*-ts-mode` via treesit-auto         |
| `vlf`            |               | Multi-GB file support (chunked loading)            |
| `symbol-overlay` |               | Highlight + navigate symbol at point               |
| `outline`        |               | Heading folding/cycling via outline-minor-mode     |
| `snippets`       |               | Yasnippet + consult picker                         |
| `format`         |               | Apheleia format-on-save, `SPC c f` smart formatter |

## `:completion` -- finding and selecting things

Minibuffer and in-buffer completion. These two modules work together
but can be enabled independently.

| Module    | Flags | Summary                                            |
|-----------|-------|----------------------------------------------------|
| `vertico` |       | Vertical minibuffer + orderless + consult + embark |
| `corfu`   |       | In-buffer popup completion + cape                  |
|           |       |                                                    |

## `:emacs` -- built-in Emacs features, enhanced

Wrappers around core Emacs functionality that add better defaults,
keybindings, and integrations.

| Module    | Flags               | Summary                                           |
|-----------|---------------------|---------------------------------------------------|
| `vc`      | `+forge`, `+gutter` | Magit, browse-at-remote, git-timemachine, diff-hl |
| `ibuffer` |                     | Enhanced buffer list with VC grouping             |
| `dired`   | `+preview`          | File manager with async ops, nerd-icons           |

## `:checkers` -- on-the-fly diagnostics

Live feedback while you edit.

| Module   | Flags | Summary                      |
|----------|-------|------------------------------|
| `syntax` |       | Flycheck + posframe tooltips |

## `:tools` -- development tooling

Language-agnostic tools that `:lang` modules build on.

| Module         | Flags   | Summary                                       |
|----------------|---------|-----------------------------------------------|
| `lsp`          | `+peek` | lsp-mode + lsp-ui + consult-lsp, perf-tuned   |
| `editorconfig` |         | Built-in EditorConfig (Emacs 30+), auto style |
| `direnv`       |         | Buffer-local direnv via envrc.el              |
| `mise`         |         | Buffer-local mise for runtime versions        |
| `just`         |         | Major mode for Justfiles via just-mode        |

External dependencies:

- **direnv**: requires the `direnv` binary on PATH
- **mise**: requires the `mise` binary on PATH
- **just**: requires `just` for the task runner; tree-sitter grammar
  installed via `treesit-auto`

## `:lang` -- language support

Per-language modes, LSP wiring, and companion tooling. Most default
to tree-sitter major modes when a grammar is available.

| Module       | Flags                       | Summary                                                     |
|--------------|-----------------------------|-------------------------------------------------------------|
| `org`        | `+roam`, `+hugo`, `+pretty` | org-modern, org-appear, org-cliplink                        |
| `markdown`   |                             | markdown-mode, xwidget live preview, mermaid                |
| `javascript` | `+deno`                     | JS/TS/TSX via tree-sitter, jest, biome/prettier auto-detect |
| `csharp`     |                             | csharp-ts-mode, dotnet minor mode, csharp-ls                |
| `elixir`     |                             | elixir-ts-mode, exunit runner, LSP via dexter               |
| `erlang`     |                             | erlang-ts-mode, ELP language server, erlfmt                 |
| `json`       |                             | json-ts-mode, auto-LSP                                      |
| `yaml`       |                             | yaml-ts-mode, auto-LSP                                      |
| `likec4`     |                             | LikeC4 architecture-as-code, tree-sitter, LSP, dev preview  |

External dependencies (when `:tools lsp` is enabled):

- **javascript**: `typescript-language-server`
  (`npm i -g typescript-language-server typescript`); `+deno` requires
  `deno` on PATH. Formatter auto-detected: prettier (if config found),
  biome (default), or `deno fmt` (in Deno projects)
- **csharp**: `csharp-ls` (`dotnet tool install -g csharp-ls`);
  `csharpier` for formatting
- **elixir**: `dexter` LSP server on PATH; `mix` for formatting
- **erlang**: ELP (Erlang Language Platform); `erlfmt` for formatting
- **json**: `vscode-json-language-server`
  (`npm i -g vscode-langservers-extracted`)
- **yaml**: `yaml-language-server` (`npm i -g yaml-language-server`)
- **likec4**: `likec4` (`brew install likec4` or `npm i -g likec4`); bundles LSP, formatter, and dev server
- **markdown**: `cmark-gfm` for live preview (no LSP)

## `:term` -- terminal emulators

| Module  | Flags | Summary                             |
|---------|-------|-------------------------------------|
| `vterm` |       | libvterm terminal, `SPC o t` toggle |

External dependencies:

- **vterm**: `cmake` + `libtool` (builds a native module on first load)

## `:llm` -- AI assistants

LLM-powered coding assistants integrated into the editor.

| Module       | Flags                                 | Summary                                         |
|--------------|---------------------------------------|-------------------------------------------------|
| `claude-ide` | `+mcp`, `+ide-diff`, `+vterm`, `+eat` | Claude Code CLI via terminal + MCP bridge       |
| `eca`        | `+completion`, `+talk`                | ECA pair-programming client: chat, rewrite, MCP |

Leader bindings live under `SPC A c` (claude) and `SPC A e` (eca) so
both modules can coexist.

External dependencies:

- **claude-ide**: requires [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
  installed and available on PATH. Terminal backend requires `vterm`
  (default, via `:term vterm`) or `eat` (via `+eat` flag).
- **eca**: the `eca` server binary is auto-downloaded on first use.
  `+talk` requires [whisper.el](https://github.com/natruj/whisper.el)
  and a local whisper model.

## `:os` -- operating system integration

| Module  | Flags | Summary                             |
|---------|-------|-------------------------------------|
| `macos` |       | Undecorated frame, Cmd key bindings |

## `:ui` -- appearance and layout

Visual tweaks, themes, and window management. None of these change
editing behaviour; they control how things look and where they appear.

| Module          | Flags                      | Summary                                       |
|-----------------|----------------------------|-----------------------------------------------|
| `dashboard`     |                            | Startup dashboard                             |
| `theme`         | `+auto`, `+light`, `+dark` | Theme switching; +auto follows OS appearance  |
| `modeline`      |                            | doom-modeline                                 |
| `fonts`         | `+ligatures`               | Font config, mixed-pitch, global text scaling |
| `treemacs`      |                            | Side-pane file tree, integrates with vc/lsp   |
| `workspaces`    |                            | Named buffer sets via persp-mode              |
| `smooth-scroll` | `+interpolate`             | Pixel-precise scrolling via ultra-scroll      |
| `hl-todo`       |                            | Highlight TODO/FIXME/HACK + consult picker    |
| `info-colors`   |                            | Colorize Info manual pages                    |
| `rainbow`       |                            | Paint CSS color literals with their color     |
