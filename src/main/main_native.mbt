///|
/// Read all lines from stdin and return as array of Items (native only)
async fn read_stdin_lines(read0 : Bool) -> Array[@core.Item] {
  let data = @stdio.stdin.read_all()
  let content = data.text()
  parse_content_to_items(content, read0)
}

///|
/// FFI: Check if stdin specifically is a TTY (for detecting pipe input)
extern "c" fn tui_stdin_is_tty() -> Int = "tui_stdin_is_tty"

///|
/// Check if stdin is a TTY (for detecting pipe input)
/// Returns true if stdin is a TTY (no pipe), false if stdin is piped
fn stdin_is_tty() -> Bool {
  tui_stdin_is_tty() != 0
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
/// FFI: Execute shell command and capture stdout into provided buffer
/// Returns number of bytes written, or -1 on error
#borrow(cmd, out_buf)
extern "c" fn tui_exec_command(
  cmd : Bytes,
  cmd_len : Int,
  out_buf : Bytes,
  out_buf_len : Int,
) -> Int = "tui_exec_command"

///|
/// Execute preview command and return output
pub fn exec_preview_sync(cmd : String) -> String {
  if cmd.length() == 0 {
    return ""
  }
  let cmd_bytes = @utf8.encode(cmd)
  // Allocate output buffer (64KB should be enough for preview)
  let out_buf_len = 65536
  let out_buf = Bytes::make(out_buf_len, 0)
  let result_len = tui_exec_command(
    cmd_bytes,
    cmd_bytes.length(),
    out_buf,
    out_buf_len,
  )
  if result_len <= 0 {
    return ""
  }
  // Decode only the relevant portion - create array and convert to bytes
  let result_arr : Array[Byte] = []
  for i = 0; i < result_len; i = i + 1 {
    result_arr.push(out_buf[i])
  }
  @utf8.decode(Bytes::from_array(result_arr)) catch {
    _ => "" // Invalid UTF-8
  }
}

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

  // Shell integration: output shell script and exit
  if opts.shell_bash {
    @io.print_raw(get_bash_script())
    return
  }
  if opts.shell_zsh {
    @io.print_raw(get_zsh_script())
    return
  }
  if opts.shell_fish {
    @io.print_raw(get_fish_script())
    return
  }

  // Get terminal size
  let (width, term_height) = @io.get_terminal_size()
  // Use --height option if specified, otherwise use terminal height
  let height = if opts.height > 0 { opts.height } else { term_height }

  // Read items from stdin (empty if no pipe input)
  let raw_items = if stdin_is_tty() {
    // No pipe input, return empty array
    []
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
    preview=opts.preview,
    preview_window=opts.preview_window,
    fetch_preview=exec_preview_sync,
  )
}

///|
fn main {
  @mbasync.run_async_main(async_main)
}
