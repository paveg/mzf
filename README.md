# mzf

A lightweight fuzzy finder written in MoonBit with fzf-compatible options.

## Features

- Fast fuzzy matching with smart case sensitivity
- Scoring algorithm based on fzf/skim
- TUI interface with keyboard navigation
- Multi-select support (`-m, --multi`)
- Field-based matching (`-n, --nth`, `-d, --delimiter`)
- Exact match mode (`-e, --exact`)
- Stdin pipe support (native build)
- Lightweight: ~550KB native binary, ~150KB JS

## Comparison

| Tool | Language | Binary Size | Features |
|------|----------|-------------|----------|
| [fzf](https://github.com/junegunn/fzf) | Go | ~4.5MB | Full-featured, preview, multi-select |
| [skim](https://github.com/lotabout/skim) | Rust | ~5MB | fzf-compatible, async |
| [peco](https://github.com/peco/peco) | Go | ~8MB | Simple, customizable |
| **mzf** | MoonBit | ~550KB | fzf-compatible, lightweight |

*Binary sizes vary by version and platform.*

mzf provides fzf-compatible options while staying lightweight. For advanced features like preview window, use fzf or skim.

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

# Show help
mzf --help
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Select current item |
| `Tab` | Toggle mark (multi-select) |
| `Esc` / `Ctrl+C` | Cancel |
| `Up` / `Ctrl+P` | Move selection up |
| `Down` / `Ctrl+N` | Move selection down |
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

### Behavior

| Option | Description |
|--------|-------------|
| `-m, --multi` | Enable multi-select |
| `--no-sort` | Don't sort results by score |
| `--tac` | Reverse input order |
| `--cycle` | Enable cyclic scroll |
| `-1, --select-1` | Auto-select if single match |
| `-0, --exit-0` | Exit immediately if no match |

### Input/Output

| Option | Description |
|--------|-------------|
| `--read0` | Read NUL-delimited input |
| `--print0` | Use NUL separator for output |
| `-f, --filter <QUERY>` | Filter mode (non-interactive) |
| `--print-query` | Print query as first line of output |
| `--expect <KEYS>` | Expected keys to abort (comma-separated) |

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
