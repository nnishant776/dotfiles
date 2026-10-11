# Doom Emacs configuration

This is a personal [Doom Emacs](https://github.com/doomemacs/core) configuration
built around Evil (Vim keybindings). It runs in one of three launch modes:

- **minimal:** fast plain-text editing, aimed at large log files.
- **default:** a lightweight editor with version control and syntax highlighting.
- **ide:** the full development environment.

All three modes share one set of files and one package download. A bridge reads
your VSCode settings, so indentation, whitespace handling, line numbers and
similar editor preferences stay the same across VSCode, Neovim and Emacs.

## Requirements

- **Emacs 30** with native compilation and tree-sitter support. The `pgtk` build
  works well, both in a terminal and graphically.
- **Command-line tools:** `git`, plus `ripgrep` (`rg`) and `fd` for fast file
  and text search.
- **A C compiler**, so tree-sitter grammars can be built on first use.
- **For ide mode only:**
  - language servers on your `PATH` for the languages you use, such as
    `gopls`, `clangd`, `nil`, `lua-language-server` and `pyright`;
  - `cmake` and `libtool` to build the vterm terminal module.

## Setup

1. Install Doom Emacs into `~/.config/emacs`:

   ```sh
   git clone https://github.com/doomemacs/core ~/.config/emacs
   ```

2. Place this directory at `~/.config/doom`.

3. Install the packages for every mode. The first command sets up ide mode and
   also generates the loader that makes the other profiles available:

   ```sh
   ~/.config/emacs/bin/doom install --no-config
   ~/.config/emacs/bin/doom --profile default sync -e
   ~/.config/emacs/bin/doom --profile minimal sync -e
   ```

   Adding `~/.config/emacs/bin` to your `PATH` lets you type `doom` on its own.

4. **Optional:** point the VSCode bridge at your settings file. By default it
   reads `~/.config/nvim/settings.json`. See
   [The VSCode settings bridge](#the-vscode-settings-bridge).

The first launch of each mode is slower than usual, because Emacs
native-compiles that mode's packages in the background. Later launches use the
compiled files.

## Launch modes

Doom fixes its module list when you run `doom sync`, so each mode is a separate
Doom *profile*. The profiles share this configuration directory and the
downloaded packages. Each one keeps its own generated init file, caches and
compiled code.

Choose a mode with the `DOOMPROFILE` environment variable:

```sh
DOOMPROFILE=minimal emacs -nw   # minimal
DOOMPROFILE=default emacs       # default
emacs                           # ide (no profile)
```

The table compares the three modes. Startup times were measured in a terminal
on the author's machine.

| | minimal | default | ide |
|---|---|---|---|
| Startup | ~0.30 s | ~0.52 s | ~0.68 s |
| Packages | 50 | 132 | 197 |
| Evil (Vim keys) | yes | yes, also in magit, dired and other special buffers | yes, also in magit, dired and other special buffers |
| Fuzzy minibuffer search (vertico) | yes | yes | yes |
| Syntax highlighting | no | tree-sitter | tree-sitter |
| Line numbers, current-line highlight | no | from VSCode settings | from VSCode settings |
| Git (magit, diff markers in the fringe) | no | yes | yes |
| File manager (dired), buffer list (ibuffer) | built-in only | yes | yes |
| Workspaces, popups, Doom modeline and icons | no | yes | yes |
| Persistent undo history | no | yes | yes |
| Auto-closing brackets (smartparens) | no | yes | yes |
| Key hints (which-key), recent files, eldoc | no | yes | yes |
| Markdown, shell and Emacs Lisp support | no | yes | yes |
| Other language modes | no | yes, without LSP | yes, with LSP |
| LSP (eglot), code completion, snippets | no | no | yes |
| Format on save, folding, indent guides | no | no | yes |
| Terminal (vterm), Org, AI agent shell | no | no | yes |

### minimal

Minimal mode is for opening and navigating large files and big chunks of text.
Its job is to be fast. It loads only:

- Evil, using Emacs's built-in undo system;
- vertico, the fuzzy menu used by `M-x`, `SPC f f`, buffer switching and so on;
- Doom's leader-key bindings;
- terminal support.

Minimal mode turns off everything that costs time on large files:

- syntax highlighting, line numbers and the current-line highlight;
- bracket matching and auto-closing brackets;
- version control (Emacs no longer runs `git` for each file it opens);
- key hints (which-key), the recent files list, eldoc and background preloading.

Some limits are raised or relaxed instead:

- **Files over 10 MB open in `fundamental-mode`.** Emacs skips the file's usual
  major mode and all of its hooks, so a 200 MB `.json` file opens as quickly as
  a plain-text file. Change the limit with `+minimal-large-file-size`.
- **The "file is large, really open?" prompt** only appears above 512 MB. Below
  that, files open without asking.
- **Changed files aren't re-read on buffer switches.** Doom normally reloads a
  changed file whenever you switch to its buffer. A log that's still being
  written would then be reloaded in full each time.
  - Run `M-x revert-buffer` to refresh a file by hand.
  - Run `M-x auto-revert-tail-mode` to follow a growing log; it only reads the
    newly appended lines.

Doom's own large-file optimizations stay on: long-line handling (`so-long`),
no bidirectional text reordering, and no fontification while you type.

On a 300 MB log, minimal mode opens the file in about one second. `G` and `gg`
are instant, and a plain-text search takes about 0.1 s. Two things remain slow
on files this big:
- **Jumping to a line number in the middle of the file**, such as
  `:1500000`, takes a few hundred milliseconds, because Emacs counts newlines
  rather than keeping a line index.
- **Regular-expression searches** are much slower than plain-text ones. Prefer
  literal patterns on very large files.

### default

Default mode adds the things a day-to-day editor needs, but no LSP:

- the Doom modeline, icons, workspaces and popup management;
- tree-sitter syntax highlighting;
- magit, and git change markers in the fringe;
- dired and ibuffer;
- persistent undo history;
- auto-closing brackets.

It supports Markdown, shell scripts, Emacs Lisp, JSON, YAML, Nix, Go, Lua,
Python, JavaScript/TypeScript, C/C++ and Zig. Evil keys also work in magit, dired
and other special buffers.

### ide

ide mode is the full setup. On top of default mode it adds:

- **eglot (LSP)** for C/C++, Go, JavaScript/TypeScript, Lua, Nix, Python, Rust
  and Zig;
- **corfu** for in-buffer completion, with orderless matching;
- **yasnippet** snippets;
- **format on save**, code folding and indent guides;
- **smooth scrolling** and a tab bar;
- **lookup** for jumping to definitions and documentation;
- the **vterm** terminal;
- **Org, reStructuredText and Ruby (with Rails) support**;
- **agent-shell** for AI coding agents.

### Running a mode as a daemon

A cold start can't match Neovim's startup time, but a running Emacs daemon can.
Connecting to one opens a terminal frame in about 0.04 seconds. Start a daemon
for minimal mode and connect to it like this:

```sh
DOOMPROFILE=minimal emacs --daemon=minimal
emacsclient -s minimal -t
```

The following alias does both. It connects to the daemon, or starts it first if
it isn't running:

```sh
alias em='DOOMPROFILE=minimal emacsclient -s minimal -t -a ""'
```

## Keeping things up to date

Run `doom sync` again whenever you change which modules or packages are enabled,
and after editing `profiles.el`. Sync each mode separately:

```sh
doom sync                          # ide; also regenerates the profile loader
doom --profile default sync -e
doom --profile minimal sync -e
```

To update Doom and all packages, run `doom upgrade`, then sync the `default` and
`minimal` profiles again.

Some caveats:

- **Never run `doom gc` or `doom sync --gc`.** Garbage collection only knows
  about the profile it runs for. It deletes packages that the other profiles
  still need.
- **Alternating syncs can be slower,** because packages only one mode uses may
  be rebuilt.
- **Restart Emacs after a sync** for the changes to take effect.

## Features

### Editor defaults

These apply in every mode. They live in `lisp/defaults.el`.

- **Indentation:** tabs are 4 columns wide and evil's `>`/`<` shift by 4,
  unless your VSCode settings say otherwise. Automatic indentation detection is
  off; indentation comes from your settings instead.
- **Line numbers** are relative by default in code, and off in text and config
  files. Your VSCode settings can change this per language or per project.
- **Bracket highlighting** is off unless your VSCode settings turn it on, and
  the cursor no longer jumps to the matching paren. Emoji rendering is also off.
- **Frames:** double buffering is disabled.

### Appearance

Appearance settings are in `lisp/ui.el` and apply in default and ide modes.

- **Light and dark themes:** `auto-dark` follows the system's light or dark
  setting and switches between `doom-feather-light` and `doom-feather-dark`. It
  checks every five seconds.
- **Other themes:** `vs-light`, `vs-dark` and `catppuccin` are also installed.
  Switch with `M-x load-theme`.
- **Modeline:** the Doom modeline shows the current workspace's name and icon.

### Languages

Language settings are in `lisp/lang.el`, and the tree-sitter features apply in
default and ide modes.

- **Grammars:** tree-sitter grammars are downloaded and built automatically the
  first time you open a file that needs one. Run
  `M-x +tree-sitter/install-missing-grammars` to install every grammar the
  enabled languages use, all at once.
- **Extra major modes:** `nix-ts-mode`, `go-template-mode` and `cue-mode`.

eglot settings only matter in ide mode:

- **Shutdown:** a language server shuts down automatically once you close its
  last buffer.
- **Disabled server features:** symbol highlighting, semantic tokens and hover
  documentation are off, which keeps the display quiet. The VSCode bridge can
  turn symbol highlighting back on.
- **Call hierarchy:** `SPC c h i` shows it.
- **Luau:** `eglot-luau` adds support for Roblox's Luau language server.
- **Sticky scroll (ide mode only):** `treesitter-context` keeps the enclosing
  function or block visible at the top of the window. It follows VSCode's
  `editor.stickyScroll.enabled`.

### Version control

Version control settings are in `lisp/vcs.el` and apply in default and ide modes.

- **magit:**
  - The tags header is hidden.
  - Logs show 20 commits.
  - The status buffer only refreshes when you ask it to, which keeps large
    repositories responsive.
- **Fringe markers:** `diff-hl` updates synchronously, one second after you stop
  typing.
- **Project roots:** both `project.el` and projectile find a project by the
  nearest `.git` directory. Projectile indexes files with external tools
  (`fd` or `git`), which is fast on large trees.

### AI agents (ide mode only)

[agent-shell](https://github.com/xenodium/agent-shell) runs AI coding agents in
an Emacs buffer. Cursor and Antigravity are set up to authenticate through their
own login flows. Start a session with `M-x agent-shell`. The configuration is in
`lisp/agent-shell.el`.

## The VSCode settings bridge

`lisp/vscode-bridge.el` reads VSCode settings files and applies them to every
buffer that visits a file. Your editor preferences then live in one place and
behave the same way across VSCode, Neovim and Emacs. The bridge runs in every
mode.

### Where settings come from

Settings are combined in VSCode's order, lowest priority first:

1. **The global settings file:** `~/.config/nvim/settings.json` by default. Set
   `+vscode-global-settings-path` to use another file.
2. **The project's workspace file:** the `"settings"` object of the
   `*.code-workspace` file at the project root.
3. **Language blocks in the global file,** such as `"[go]": { … }`.
4. **Language blocks in the workspace file.**
5. **Mode overrides.** In minimal mode, a fixed set of display settings is
   forced off. See [Minimal mode overrides](#minimal-mode-overrides).

As in VSCode, a language-specific setting beats a general one, even one from a
more specific scope. Settings are applied again whenever a buffer's major mode
changes. Saving a settings file or a workspace file updates every open buffer
straight away. To update them all by hand, run `M-x +vscode/reapply`.

The bridge only touches buffers for code, text and config files. It never
touches magit, terminals, shells, agent-shell, dired or help buffers. It also
skips files with no major mode, such as large files opened in minimal mode.

### Supported settings

| VSCode setting | Effect in Emacs |
|---|---|
| `editor.tabSize` | Tab width, the major mode's indent width, and evil's shift width |
| `editor.insertSpaces` | Indent with spaces or with tabs |
| `editor.lineNumbers` | `"relative"`, `"on"` or `"interval"` show line numbers; `"off"` hides them |
| `editor.renderLineHighlight` | Highlights the current line, unless set to `"none"` |
| `editor.matchBrackets` | `"near"` highlights the bracket next to the cursor; `"always"` also highlights the enclosing pair; `"never"` turns highlighting off |
| `editor.guides.indentation` | Shows or hides indent guides (ide mode) |
| `editor.stickyScroll.enabled` | Turns sticky scroll on or off (ide mode) |
| `editor.occurrencesHighlight` | Turns LSP highlighting of the symbol under the cursor on or off (ide mode) |
| `editor.formatOnSave` | Turns format-on-save on or off (ide mode) |
| `editor.wordWrapColumn` | Sets the fill column |
| `files.trimTrailingWhitespace` | Removes trailing spaces on save, without deleting blank lines at the end of the file |
| `files.trimFinalNewlines` | Removes extra blank lines at the end of the file on save |
| `files.insertFinalNewline` | Ensures the file ends with a newline |
| `files.associations` | Picks the major mode for matching files, such as `"*.tmpl": "gotmpl"` |

Workspace associations take priority over global ones.

### Language IDs

Language blocks such as `"[yaml]"` use VSCode's language IDs. A block applies to
buffers whose major mode is, or derives from, one of the modes listed below.
Tree-sitter variants are matched too.

| Language ID | Emacs major modes |
|---|---|
| `go` | `go-mode`, `go-ts-mode` |
| `gotmpl` | `go-template-mode` |
| `yaml` | `yaml-mode`, `yaml-ts-mode` |
| `python` | `python-mode`, `python-ts-mode` |
| `javascript` | `js-mode`, `js-ts-mode` |
| `typescript` | `typescript-mode`, `typescript-ts-mode` |
| `markdown` | `markdown-mode`, `markdown-ts-mode` |
| `lua` | `lua-mode`, `lua-ts-mode` |
| `make` | `makefile-mode` |
| `nix` | `nix-mode`, `nix-ts-mode` |
| `json`, `code-workspace` | `json-ts-mode`, `js-json-mode` |
| `cue` | `cue-mode` |

To add a language, extend `+vscode-language-modes`.

### Example

A workspace file like this gives the project 2-space indentation and trailing
whitespace trimming, and uses tabs for Go:

```json
{
  "folders": [{ "path": "." }],
  "settings": {
    "editor.tabSize": 2,
    "files.trimTrailingWhitespace": true,
    "[go]": { "editor.insertSpaces": false, "editor.tabSize": 8 }
  }
}
```

### Minimal mode overrides

In minimal mode, the bridge forces these settings after all the others:

```
editor.lineNumbers          = "off"
editor.renderLineHighlight  = "none"
editor.matchBrackets        = "never"
editor.guides.indentation   = false
editor.stickyScroll.enabled = false
```

Editing settings still follow your files: tab width, tabs or spaces, whitespace
trimming and final newlines. Change the list in `+vscode-mode-overrides`.

## File layout

| File | Purpose |
|---|---|
| `init.el` | Defines the launch mode (`+mode`) and the Doom modules each mode enables |
| `profiles.el` | Declares the `minimal` and `default` profiles |
| `packages.el` | Extra packages, and which modes install each one |
| `config.el` | Loads the files in `lisp/` that the current mode needs |
| `lisp/defaults.el` | Core editor defaults, plus the minimal-mode tuning |
| `lisp/vscode-bridge.el` | The VSCode settings bridge |
| `lisp/ui.el` | Themes and modeline (default and ide) |
| `lisp/lang.el` | tree-sitter, eglot and smartparens settings (default and ide) |
| `lisp/vcs.el` | magit, diff-hl and project detection (default and ide) |
| `lisp/agent-shell.el` | AI agent settings (ide) |
| `custom.el` | Settings saved by Emacs's Customize interface |

Inside Emacs Lisp files, `+mode` holds the current mode as `minimal`, `default`
or `ide`. `(+mode>= 'default)` returns true in default and ide modes, which is
handy for code that should skip minimal mode.

### Adding a module or package to a mode

- **Modules:** in the `doom!` block in `init.el`, wrap the module in
  `(:when (+mode>= 'default) …)` or `(:when (+mode>= 'ide) …)`. Use
  `(:if (+mode>= 'ide) A B)` to pick between two variants, such as a language
  with or without `+lsp`.
- **Packages:** in `packages.el`, add `:disable (eq +mode 'minimal)` or
  `:disable (not (+mode>= 'ide))` to a `package!` line.

Then sync the profiles that changed.

## Troubleshooting

- **"Profiles not initialized yet; run 'doom sync' first".** Run `doom sync`
  without a profile. It generates the loader that makes `DOOMPROFILE` work.
- **A mode loads the wrong modules.** Make sure you synced that profile with
  `doom --profile NAME sync`. Running `doom sync` on its own only updates ide
  mode.
- **vterm asks to compile its module.** Answer yes, or run
  `M-x vterm-module-compile`. Building it needs `cmake`, `libtool` and a C
  compiler.
- **A file has no syntax highlighting in default or ide mode.** Its tree-sitter
  grammar may be missing. Run `M-x +tree-sitter/install-missing-grammars`.
- **A setting in your settings file isn't applied.**
  - Check the buffer's resolved settings with `M-: +vscode--settings`.
  - Check that the project root is where you expect with `M-: (doom-project-root)`.
