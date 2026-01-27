///|
/// Read all lines from stdin and return as array of Items (native only)
async fn read_stdin_lines(read0 : Bool) -> Array[@core.Item] {
  let items : Array[@core.Item] = []
  // Read all stdin content
  let data = @stdio.stdin.read_all()
  let content = data.text()

  // Choose delimiter based on read0 option
  let delimiter = if read0 { '\u0000' } else { '\n' }

  // Split into lines
  let mut idx = 0
  let mut start = 0
  let chars : Array[Char] = content.iter().collect()
  let len = chars.length()
  for i = 0; i < len; i = i + 1 {
    if chars[i] == delimiter {
      if i > start {
        let buf = StringBuilder::new()
        for j = start; j < i; j = j + 1 {
          // Skip carriage return when not using read0
          if not(read0) && chars[j] == '\r' {
            continue
          }
          buf.write_char(chars[j])
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

  // Handle last line without delimiter
  if start < len {
    let buf = StringBuilder::new()
    for j = start; j < len; j = j + 1 {
      if not(read0) && chars[j] == '\r' {
        continue
      }
      buf.write_char(chars[j])
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
  let (width, term_height) = @io.get_terminal_size()
  // Use --height option if specified, otherwise use terminal height
  let height = if opts.height > 0 { opts.height } else { term_height }

  // Read items from stdin or use demo data
  let raw_items = if stdin_is_tty() {
    // No pipe input, use demo data for testing
    get_demo_items()
  } else {
    // Read from stdin pipe (use read0 for NUL-delimited input)
    read_stdin_lines(opts.read0)
  }

  // Apply --tac if specified (reverse input order)
  let items = if opts.tac { reverse_items(raw_items) } else { raw_items }

  // Handle --filter: non-interactive filter mode
  if opts.filter.length() > 0 {
    // Filter items using the pattern
    let filtered = if opts.exact {
      if opts.no_sort {
        @core.filter_exact_no_sort(opts.filter, items, opts.ignore_case)
      } else {
        @core.filter_exact(opts.filter, items, opts.ignore_case)
      }
    } else if opts.ignore_case {
      if opts.no_sort {
        @core.filter_without_sort_ignore_case(opts.filter, items)
      } else {
        @core.filter_and_score_ignore_case(opts.filter, items)
      }
    } else if opts.no_sort {
      @core.filter_without_sort(opts.filter, items)
    } else {
      @core.filter_and_score(opts.filter, items)
    }

    // Output print_query first if requested
    if opts.print_query {
      if opts.print0 {
        @io.print_raw(opts.filter)
        @io.print_raw("\u0000")
      } else {
        println(opts.filter)
      }
    }

    // Output matching items
    for result in filtered {
      if opts.print0 {
        @io.print_raw(result.item.text)
        @io.print_raw("\u0000")
      } else {
        println(result.item.text)
      }
    }
    return
  }
  run_app(
    items,
    width,
    height,
    initial_query=opts.query,
    reverse=opts.reverse,
    prompt=opts.prompt,
    pointer=opts.pointer,
    marker=opts.marker,
    cycle=opts.cycle,
    no_sort=opts.no_sort,
    nth=opts.nth,
    delimiter=opts.delimiter,
    select_1=opts.select_1,
    exit_0=opts.exit_0,
    print0=opts.print0,
    exact=opts.exact,
    ignore_case=opts.ignore_case,
    header=opts.header,
    print_query=opts.print_query,
  )
}

///|
fn main {
  @mbasync.run_async_main(async_main)
}
