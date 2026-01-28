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
  let history : Array[String] = []
  if path.length() == 0 {
    return history
  }
  let content = js_read_file_sync(path)
  if content.length() == 0 {
    return history
  }
  // Split by newlines
  let chars : Array[Char] = content.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '\n' {
      let line = buf.to_string()
      if line.length() > 0 {
        history.push(line)
      }
      buf.reset()
    } else if chars[i] != '\r' {
      buf.write_char(chars[i])
    }
  }
  // Handle last line without newline
  let last_line = buf.to_string()
  if last_line.length() > 0 {
    history.push(last_line)
  }
  history
}

///|
/// Write history file (fzf-compatible: read, append, truncate, write)
fn write_history_js(path : String, query : String, max_size : Int) -> Unit {
  if path.length() == 0 || query.length() == 0 {
    return
  }
  // Read existing history
  let history = read_history_file_js(path)
  // Append new query
  history.push(query)
  // Truncate if exceeds max_size
  let start = if history.length() > max_size {
    history.length() - max_size
  } else {
    0
  }
  // Build output
  let buf = StringBuilder::new()
  for i = start; i < history.length(); i = i + 1 {
    buf.write_string(history[i])
    buf.write_string("\n")
  }
  // Write to file
  js_write_file_sync(path, buf.to_string())
}

///|
/// Parse stdin content into Items
fn parse_stdin_to_items(content : String, read0 : Bool) -> Array[@core.Item] {
  let items : Array[@core.Item] = []
  let delimiter = if read0 { '\u0000' } else { '\n' }
  let chars : Array[Char] = content.iter().collect()
  let len = chars.length()
  let mut idx = 0
  let mut start = 0
  for i = 0; i < len; i = i + 1 {
    if chars[i] == delimiter {
      if i > start {
        let buf = StringBuilder::new()
        for j = start; j < i; j = j + 1 {
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
  let items = if opts.tac { reverse_items(raw_items) } else { raw_items }

  // Handle --filter: non-interactive filter mode
  if opts.filter.length() > 0 {
    let case_sensitive = if opts.ignore_case {
      false
    } else {
      @core.has_uppercase_query(opts.filter)
    }
    let filtered = if opts.extended {
      if opts.no_sort {
        @core.filter_extended_no_sort(opts.filter, items, case_sensitive)
      } else {
        @core.filter_extended(opts.filter, items, case_sensitive)
      }
    } else if opts.exact {
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
    header=opts.header,
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
