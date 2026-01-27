///|
/// Read all lines from stdin and return as array of Items (native only)
async fn read_stdin_lines() -> Array[@core.Item] {
  let items : Array[@core.Item] = []
  // Read all stdin content
  let data = @stdio.stdin.read_all()
  let content = data.text()

  // Split into lines
  let mut idx = 0
  let mut start = 0
  let chars : Array[Char] = content.iter().collect()
  let len = chars.length()
  for i = 0; i < len; i = i + 1 {
    if chars[i] == '\n' {
      if i > start {
        let buf = StringBuilder::new()
        for j = start; j < i; j = j + 1 {
          if chars[j] != '\r' {
            buf.write_char(chars[j])
          }
        }
        let line = buf.to_string()
        if line.length() > 0 {
          items.push(@core.Item::new(line, idx))
          idx = idx + 1
        }
      }
      start = i + 1
    }
  }

  // Handle last line without newline
  if start < len {
    let buf = StringBuilder::new()
    for j = start; j < len; j = j + 1 {
      if chars[j] != '\r' {
        buf.write_char(chars[j])
      }
    }
    let line = buf.to_string()
    if line.length() > 0 {
      items.push(@core.Item::new(line, idx))
    }
  }
  items
}

///|
/// Check if stdin is a TTY (for detecting pipe input)
fn stdin_is_tty() -> Bool {
  @io.is_tty()
}

///|
async fn async_main() -> Unit {
  // Parse CLI options
  let opts = parse_args()
  if opts.show_help {
    print_help()
    return
  }
  if opts.show_version {
    print_version()
    return
  }

  // Get terminal size
  let (width, height) = @io.get_terminal_size()

  // Read items from stdin or use demo data
  let items = if stdin_is_tty() {
    // No pipe input, use demo data for testing
    get_demo_items()
  } else {
    // Read from stdin pipe
    read_stdin_lines()
  }
  run_app(items, width, height, initial_query=opts.query)
}

///|
fn main {
  @mbasync.run_async_main(async_main)
}
