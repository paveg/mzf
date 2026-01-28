///|
/// Read all lines from stdin and return as array of Items (native only)
async fn read_stdin_lines(read0 : Bool) -> Array[@core.Item] {
  let data = @stdio.stdin.read_all()
  let content = data.text()
  parse_content_to_items(content, read0)
}

///|
/// Check if stdin is a TTY (for detecting pipe input)
fn stdin_is_tty() -> Bool {
  @io.is_tty()
}

///|
/// FFI: Read file contents (sync) - returns content as Bytes and length
#borrow(path, out_len)
extern "c" fn tui_read_file(
  path : Bytes,
  path_len : Int,
  out_len : FixedArray[Int],
) -> Bytes = "tui_read_file"

///|
/// FFI: Write file contents (sync)
#borrow(path, content)
extern "c" fn tui_write_file(
  path : Bytes,
  path_len : Int,
  content : Bytes,
  content_len : Int,
) -> Int = "tui_write_file"

///|
/// Read history file synchronously and return lines as array
fn read_history_file_sync(path : String) -> Array[String] {
  if path.length() == 0 {
    return []
  }
  let path_bytes = @utf8.encode(path)
  let out_len : FixedArray[Int] = [0]
  let content_bytes = tui_read_file(path_bytes, path_bytes.length(), out_len)
  if out_len[0] == 0 {
    return []
  }
  let content = @utf8.decode(content_bytes) catch {
    _ => return [] // Invalid UTF-8
  }
  parse_history_content(content)
}

///|
/// Write history file synchronously (fzf-compatible: read, append, truncate, write)
pub fn write_history_sync(
  path : String,
  query : String,
  max_size : Int,
) -> Unit {
  if path.length() == 0 || query.length() == 0 {
    return
  }
  let history = read_history_file_sync(path)
  let output = build_history_output(history, query, max_size)
  let path_bytes = @utf8.encode(path)
  let content_bytes = @utf8.encode(output)
  ignore(
    tui_write_file(
      path_bytes,
      path_bytes.length(),
      content_bytes,
      content_bytes.length(),
    ),
  )
}

///|
/// Read history file and return lines as array (for startup loading)
async fn read_history_file(path : String) -> Array[String] {
  if path.length() == 0 {
    return []
  }
  let content = @fs.read_file(path).text() catch {
    _ => return [] // File doesn't exist or can't be read
  }
  parse_history_content(content)
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
  let tac_items = if opts.tac { reverse_items(raw_items) } else { raw_items }

  // Handle --header-lines: extract first N lines as header
  let extraction = extract_header_lines(tac_items, opts.header_lines)
  let items = extraction.items
  let combined_header = combine_headers(extraction.header, opts.header)

  // Load history from file if specified
  let history = read_history_file(opts.history)

  // Handle --filter: non-interactive filter mode
  if opts.filter.length() > 0 {
    let filtered = filter_items_batch(
      opts.filter,
      items,
      opts.extended,
      opts.exact,
      opts.ignore_case,
      opts.no_sort,
    )
    output_filter_results(filtered, opts.filter, opts.print_query, opts.print0)
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
    multi=opts.multi,
    cycle=opts.cycle,
    no_sort=opts.no_sort,
    nth=opts.nth,
    delimiter=opts.delimiter,
    select_1=opts.select_1,
    exit_0=opts.exit_0,
    print0=opts.print0,
    extended=opts.extended,
    exact=opts.exact,
    ignore_case=opts.ignore_case,
    header=combined_header,
    print_query=opts.print_query,
    with_nth=opts.with_nth,
    expect=opts.expect,
    ansi=opts.ansi,
    history~,
    on_select=fn(query) {
      write_history_sync(opts.history, query, opts.history_size)
    },
    border=opts.border,
    info=opts.info,
    layout=opts.layout,
    color=opts.color,
  )
}

///|
fn main {
  @mbasync.run_async_main(async_main)
}
