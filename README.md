# mzf

A lightweight fuzzy finder written in MoonBit.

## Features

- Fast fuzzy matching with smart case sensitivity
- Scoring algorithm based on fzf/skim
- TUI interface with keyboard navigation
- Stdin pipe support (native build)
- Lightweight: ~400KB native binary, ~110KB JS

## Comparison

| Tool | Language | Binary Size | Features |
|------|----------|-------------|----------|
| [fzf](https://github.com/junegunn/fzf) | Go | ~4.5MB | Full-featured, preview, multi-select |
| [skim](https://github.com/lotabout/skim) | Rust | ~5MB | fzf-compatible, async |
| [peco](https://github.com/peco/peco) | Go | ~8MB | Simple, customizable |
| **mzf** | MoonBit | ~400KB | Minimal, lightweight |

*Binary sizes vary by version and platform.*

mzf is designed to be minimal and lightweight. For advanced features like preview or multi-select, use fzf or skim.

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

# Show help
mzf --help
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Select current item |
| `Esc` / `Ctrl+C` | Cancel |
| `Up` / `Ctrl+P` | Move selection up |
| `Down` / `Ctrl+N` | Move selection down |
| `Backspace` | Delete character |

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
