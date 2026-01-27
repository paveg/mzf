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
- Stdin pipe support (both native and JS builds)
- Lightweight: ~541KB native binary, ~228KB JS

### Not Yet Implemented

The following fzf features are not yet supported:

- `--preview`, `--preview-window` (preview pane)
- `--bind` (custom key bindings)
- Extended search syntax (`^prefix`, `suffix$`, `'exact`, `!negation`)
- `--header-lines`
- `--disabled` (disable search)
- `--tmux` (tmux integration)
- Shell completion scripts (bash, zsh, fish)

## Comparison

| Tool | Language | Binary Size | Features |
|------|----------|-------------|----------|
| [fzf](https://github.com/junegunn/fzf) | Go | ~3.5MB | Full-featured, preview, multi-select |
| [skim](https://github.com/lotabout/skim) | Rust | ~3.9MB | fzf-compatible, async |
| [peco](https://github.com/peco/peco) | Go | ~4.7MB | Simple, customizable |
| **mzf** | MoonBit | **~541KB** | fzf-compatible, lightweight |

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
| `Ctrl+P` / `Ctrl+N` | History prev/next (with --history) |
| `Ctrl+U` | Clear query |
| `Backspace` | Delete character |

## Options

### Search

| Option | Description |
|--------|-------------|
| `-q, --query <QUERY>` | Start with the given query |
| `-e, --exact` | Exact-match mode (substring) |
| `-i, --ignore-case` | Force case-insensitive matching |
| `-n, --nth <N[,M,...]>` | Match only in specified fields |
| `-d, --delimiter <STR>` | Field delimiter |

### Display

| Option | Description |
|--------|-------------|
| `--reverse` | Display from top to bottom |
| `--height <N>` | Maximum height (default: full screen) |
| `--prompt <STR>` | Input prompt (default: "> ") |
| `--pointer <STR>` | Pointer to current line (default: "> ") |
| `--marker <STR>` | Multi-select marker (default: "*") |
| `--header <STR>` | Header string to display |
| `--with-nth <N[,M,...]>` | Field index for display transformation |
| `--ansi` | Enable ANSI color processing |
| `--border <STYLE>` | Border style (none, rounded, sharp, horizontal) |
| `--info <STYLE>` | Info line style (default, hidden, inline) |
| `--layout <LAYOUT>` | Layout (default, reverse, reverse-list) |
| `--color <SPEC>` | Color scheme (prompt:yellow,pointer:cyan,...) |

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

## Building

```bash
# Build native binary
make native

# Build JS target
make js

# Run tests
make test
```

## License

MIT
