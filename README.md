# mzf

A lightweight fuzzy finder written in MoonBit with fzf-compatible options.

## Features

- Fast fuzzy matching with smart case sensitivity
- Scoring algorithm based on fzf/skim
- TUI interface with keyboard navigation
- Multi-select support (`-m, --multi`)
- Field-based matching (`-n, --nth`, `-d, --delimiter`)
- Exact match mode (`-e, --exact`)
- ANSI color support (`--ansi`)
- History support (`--history`)
- Preview pane support (`--preview`)
- Stdin pipe support (both native and JS builds)
- Extended search mode (`-x, --extended`)
- Shell integration (Bash, Zsh, Fish)
- Lightweight: ~636KB native binary, ~318KB JS

## Comparison

| Tool | Language | Binary Size | Features |
|------|----------|-------------|----------|
| [fzf](https://github.com/junegunn/fzf) | Go | ~3.5MB | Full-featured, preview, multi-select |
| [skim](https://github.com/lotabout/skim) | Rust | ~3.9MB | fzf-compatible, async |
| [peco](https://github.com/peco/peco) | Go | ~4.7MB | Simple, customizable |
| **mzf** | MoonBit | **~636KB** | fzf-compatible, preview, shell integration, lightweight |

*mzf is ~6x smaller than alternatives while providing fzf-compatible options.*

## Installation

### npm

```bash
npm install -g @paveg/mzf
```

### From Source

Requires [MoonBit](https://www.moonbitlang.com/) toolchain.

```bash
git clone https://github.com/paveg/mzf.git
cd mzf
moon install
make
make install  # installs to ~/.local/bin/mzf
```

## Usage

```bash
# Pipe input to mzf
find . -type f | mzf

# With initial query
ls | mzf -q "test"

# Multi-select mode
find . -type f | mzf -m

# Exact match mode
ls | mzf -e -q txt

# Field-based matching (match 1st and 2nd fields)
ps aux | mzf -n 1,2 -d ' '

# Reverse display order
ls | mzf --reverse

# Custom prompt and pointer
ls | mzf --prompt='Search: ' --pointer='▶ '

# Filter mode (non-interactive)
find . | mzf -f src

# With history support
ls | mzf --history ~/.mzf_history

# Preserve ANSI colors
ls --color=always | mzf --ansi

# Custom color scheme
ls | mzf --color=prompt:red,pointer:blue,hl:green

# Preview file contents
find . -type f | mzf --preview 'cat {}'

# Preview with bottom layout
find . -type f | mzf --preview 'head -20 {}' --preview-window bottom:40%

# Show help
mzf --help
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Select current item |
| `Tab` | Toggle mark (multi-select, requires -m) |
| `Esc` / `Ctrl+C` | Cancel |
| `Up` / `Down` | Move selection / History navigation |
| `Page Up` / `Page Down` | Move selection by page |
| `Ctrl+P` / `Ctrl+N` | History prev/next (with --history) |
| `Ctrl+U` | Clear query |
| `Backspace` | Delete character |

## Options

### Search

| Option | Description |
|--------|-------------|
| `-x, --extended` | Extended search mode (see below) |
| `-q, --query <QUERY>` | Start with the given query |
| `-e, --exact` | Exact-match mode (substring) |
| `-i, --ignore-case` | Force case-insensitive matching |
| `-n, --nth <N[,M,...]>` | Match only in specified fields |
| `-d, --delimiter <STR>` | Field delimiter |

#### Extended Search Mode (`-x`)

| Token | Match type | Description |
|-------|-----------|-------------|
| `term` | fuzzy | Default fuzzy match |
| `^term` | prefix | Starts with `term` |
| `term$` | suffix | Ends with `term` |
| `'term` | exact | Exact substring match |
| `!term` | inverse | Exclude items matching `term` |
| `!^term` | inverse prefix | Exclude items starting with `term` |
| `term1 term2` | AND | Both terms must match |
| `term1 \| term2` | OR | Either term matches |

### Display

| Option | Description |
|--------|-------------|
| `--reverse` | Display from top to bottom |
| `--height <N>` | Maximum height (default: full screen) |
| `--prompt <STR>` | Input prompt (default: "> ") |
| `--pointer <STR>` | Pointer to current line (default: "> ") |
| `--marker <STR>` | Multi-select marker (default: "*") |
| `--header <STR>` | Header string to display |
| `--header-lines <N>` | First N lines of input as header |
| `--with-nth <N[,M,...]>` | Field index for display transformation |
| `--ansi` | Enable ANSI color processing |
| `--border <STYLE>` | Border style (none, rounded, sharp, horizontal) |
| `--info <STYLE>` | Info line style (default, hidden, inline) |
| `--layout <LAYOUT>` | Layout (default, reverse, reverse-list) |
| `--color <SPEC>` | Color scheme (prompt:yellow,pointer:cyan,...) |

### Preview

| Option | Description |
|--------|-------------|
| `--preview <CMD>` | Command to preview selected item |
| `--preview-window <SPEC>` | Preview window layout (right:50%, bottom:40%) |

#### Preview Placeholders

| Placeholder | Description |
|-------------|-------------|
| `{}` | Current line (shell-escaped) |
| `{f}` | Current line (quoted, same as {}) |
| `{n}` | Line number (1-indexed) |
| `{q}` | Current query string |
| `{+}` | All marked items (space-separated) |
| `{+n}` | Line numbers of marked items |

### Behavior

| Option | Description |
|--------|-------------|
| `-m, --multi` | Enable multi-select |
| `--no-sort` | Don't sort results by score |
| `--tac` | Reverse input order |
| `--cycle` | Enable cyclic scroll |
| `-1, --select-1` | Auto-select if single match |
| `-0, --exit-0` | Exit immediately if no match |
| `--expect <KEYS>` | Expected keys to abort (comma-separated) |

### Input/Output

| Option | Description |
|--------|-------------|
| `--read0` | Read NUL-delimited input |
| `--print0` | Use NUL separator for output |
| `-f, --filter <QUERY>` | Filter mode (non-interactive) |
| `--print-query` | Print query as first line of output |
| `--history <FILE>` | History file path |
| `--history-size <N>` | Maximum history size (default: 1000) |

### Shell Integration

| Option | Description |
|--------|-------------|
| `--bash` | Output bash integration script |
| `--zsh` | Output zsh integration script |
| `--fish` | Output fish integration script |

## Shell Integration

mzf provides shell integration for Bash, Zsh, and Fish with key bindings and completion.

### Setup

```bash
# Bash: Add to ~/.bashrc
eval "$(mzf --bash)"

# Zsh: Add to ~/.zshrc
source <(mzf --zsh)

# Fish: Add to ~/.config/fish/config.fish
mzf --fish | source
```

### Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl-T` | File selection (paste to command line) |
| `Ctrl-R` | History search |
| `Alt-C` | cd to selected directory |

### Completion

Type `**` followed by `Tab` to trigger fuzzy completion:

```bash
vim **<Tab>      # Fuzzy file completion
cd **<Tab>       # Fuzzy directory completion
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MZF_CTRL_T_COMMAND` | File listing command for Ctrl-T | `find . -type f` |
| `MZF_CTRL_T_OPTS` | Options for Ctrl-T | (none) |
| `MZF_ALT_C_COMMAND` | Directory listing command for Alt-C | `find . -type d` |
| `MZF_ALT_C_OPTS` | Options for Alt-C | (none) |
| `MZF_CTRL_R_OPTS` | Options for Ctrl-R (history) | (none) |
| `MZF_COMPLETION_TRIGGER` | Completion trigger | `**` |
| `MZF_COMPLETION_OPTS` | Options for completion | (none) |

#### Example: Use fd instead of find

```bash
# In ~/.bashrc or ~/.zshrc
export MZF_CTRL_T_COMMAND='fd --type f'
export MZF_ALT_C_COMMAND='fd --type d'
```

## Building

```bash
# Build native binary
make native

# Build JS target
make js

# Run tests
make test
```

## fzf Compatibility

| Category | Option | fzf | mzf | Notes |
|----------|--------|:---:|:---:|-------|
| **Search** | `-x, --extended` | ✅ | ✅ | Extended search syntax (`^`, `$`, `'`, `!`) |
| | `-e, --exact` | ✅ | ✅ | |
| | `-i, --ignore-case` | ✅ | ✅ | |
| | `+i` (case-sensitive) | ✅ | ❌ | |
| | `--literal` | ✅ | ❌ | |
| | `--algo` | ✅ | ❌ | |
| | `-n, --nth` | ✅ | ✅ | |
| | `--with-nth` | ✅ | ✅ | |
| | `-d, --delimiter` | ✅ | ✅ | |
| | `--disabled` | ✅ | ❌ | |
| **Interface** | `-m, --multi` | ✅ | ✅ | |
| | `--bind` | ✅ | ❌ | Custom key bindings |
| | `--cycle` | ✅ | ✅ | |
| | `--wrap` | ✅ | ❌ | |
| | `--no-mouse` | ✅ | - | mzf has no mouse support |
| **Layout** | `--height` | ✅ | ✅ | mzf: lines only (no %) |
| | `--layout` | ✅ | ✅ | |
| | `--reverse` | ✅ | ✅ | |
| | `--border` | ✅ | ✅ | mzf: none/rounded/sharp/horizontal |
| | `--border-label` | ✅ | ❌ | |
| | `--margin` | ✅ | ❌ | |
| | `--padding` | ✅ | ❌ | |
| | `--info` | ✅ | ✅ | |
| | `--prompt` | ✅ | ✅ | |
| | `--pointer` | ✅ | ✅ | |
| | `--marker` | ✅ | ✅ | |
| | `--header` | ✅ | ✅ | |
| | `--header-lines` | ✅ | ✅ | |
| **Display** | `--ansi` | ✅ | ✅ | |
| | `--color` | ✅ | ✅ | mzf: subset of color options |
| | `--tabstop` | ✅ | ❌ | |
| | `--highlight-line` | ✅ | ❌ | |
| **History** | `--history` | ✅ | ✅ | |
| | `--history-size` | ✅ | ✅ | |
| **Preview** | `--preview` | ✅ | ✅ | Preview pane |
| | `--preview-window` | ✅ | ✅ | mzf: right/bottom only |
| **Output** | `-q, --query` | ✅ | ✅ | |
| | `-1, --select-1` | ✅ | ✅ | |
| | `-0, --exit-0` | ✅ | ✅ | |
| | `-f, --filter` | ✅ | ✅ | |
| | `--print-query` | ✅ | ✅ | |
| | `--expect` | ✅ | ✅ | |
| | `--read0` | ✅ | ✅ | |
| | `--print0` | ✅ | ✅ | |
| **Behavior** | `--no-sort` | ✅ | ✅ | |
| | `--tac` | ✅ | ✅ | |
| | `--sync` | ✅ | ❌ | |
| | `--listen` | ✅ | ❌ | |
| **Integration** | `--tmux` | ✅ | ❌ | |
| | Shell integration | ✅ | ✅ | `--bash`, `--zsh`, `--fish` |

## License

MIT
