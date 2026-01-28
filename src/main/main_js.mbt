///|
/// Check if stdin is a TTY (JS version)
extern "js" fn js_stdin_is_tty() -> Bool =
  #| () => process.stdin.isTTY === true

///|
/// Read all stdin content (for piped input)
extern "js" fn js_read_stdin_all() -> @js_async.Promise[String] =
  #| async () => {
  #|   const chunks = [];
  #|   process.stdin.setEncoding('utf8');
  #|   for await (const chunk of process.stdin) {
  #|     chunks.push(chunk);
  #|   }
  #|   return chunks.join('');
  #| }

///|
/// Read file contents (sync, for history)
extern "js" fn js_read_file_sync(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return fs.readFileSync(path, 'utf8');
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

///|
/// Write file contents (sync, for history)
extern "js" fn js_write_file_sync(path : String, content : String) -> Unit =
  #| (path, content) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.writeFileSync(path, content, 'utf8');
  #|   } catch (e) {
  #|     // Ignore write errors
  #|   }
  #| }

///|
/// Read history file and return lines as array (JS version)
fn read_history_file_js(path : String) -> Array[String] {
  if path.length() == 0 {
    return []
  }
  let content = js_read_file_sync(path)
  parse_history_content(content)
}

///|
/// Write history file (fzf-compatible: read, append, truncate, write)
fn write_history_js(path : String, query : String, max_size : Int) -> Unit {
  if path.length() == 0 || query.length() == 0 {
    return
  }
  let history = read_history_file_js(path)
  let output = build_history_output(history, query, max_size)
  js_write_file_sync(path, output)
}

///|
/// Parse stdin content into Items (uses common function)
fn parse_stdin_to_items(content : String, read0 : Bool) -> Array[@core.Item] {
  parse_content_to_items(content, read0)
}

///|
async fn js_main() -> Unit {
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
  let height = if opts.height > 0 { opts.height } else { term_height }

  // Read items from stdin or use demo data
  let raw_items = if js_stdin_is_tty() {
    // No pipe input, use demo data for testing
    get_demo_items()
  } else {
    // Read from stdin pipe
    let content = @js_async.Promise::wait(js_read_stdin_all())
    parse_stdin_to_items(content, opts.read0)
  }

  // Apply --tac if specified (reverse input order)
  let tac_items = if opts.tac { reverse_items(raw_items) } else { raw_items }

  // Handle --header-lines: extract first N lines as header
  let extraction = extract_header_lines(tac_items, opts.header_lines)
  let items = extraction.items
  let combined_header = combine_headers(extraction.header, opts.header)

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

  // Load history from file
  let history = read_history_file_js(opts.history)
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
      write_history_js(opts.history, query, opts.history_size)
    },
    border=opts.border,
    info=opts.info,
    layout=opts.layout,
    color=opts.color,
  )
}

///|
fn main {
  @mbasync.run_async_main(js_main)
}
