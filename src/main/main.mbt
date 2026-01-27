///|
/// Get demo items for testing when no stdin input
fn get_demo_items() -> Array[@core.Item] {
  [
    @core.Item::new("src/main/main.mbt", 0),
    @core.Item::new("src/core/types.mbt", 1),
    @core.Item::new("src/core/matcher.mbt", 2),
    @core.Item::new("src/ui/app.mbt", 3),
    @core.Item::new("src/ui/highlight.mbt", 4),
    @core.Item::new("moon.mod.json", 5),
    @core.Item::new("README.md", 6),
    @core.Item::new("examples/demo.mbt", 7),
    @core.Item::new("tests/matcher_test.mbt", 8),
    @core.Item::new("docs/design.md", 9),
  ]
}

///|
/// Run the main application with options
fn run_app(
  items : Array[@core.Item],
  width : Int,
  height : Int,
  initial_query? : String = "",
  reverse? : Bool = false,
  prompt? : String = "> ",
  pointer? : String = "> ",
  marker? : String = "*",
  multi? : Bool = false,
  cycle? : Bool = false,
  no_sort? : Bool = false,
  nth? : String = "",
  delimiter? : String = "",
  select_1? : Bool = false,
  exit_0? : Bool = false,
  print0? : Bool = false,
  exact? : Bool = false,
  ignore_case? : Bool = false,
  header? : String = "",
  print_query? : Bool = false,
  with_nth? : String = "",
  expect? : String = "",
  ansi? : Bool = false,
  history? : Array[String] = [],
  on_select? : (String) -> Unit = fn(_q) {  },
) -> Unit {
  if items.length() == 0 {
    if exit_0 {
      // Exit immediately with no output
      return
    }
    return
  }
  let app = @ui.App::new(
    items,
    width,
    height,
    initial_query~,
    reverse~,
    prompt~,
    pointer~,
    marker~,
    multi~,
    cycle~,
    no_sort~,
    nth~,
    delimiter~,
    exact~,
    ignore_case~,
    header~,
    with_nth~,
    expect~,
    ansi~,
    history~,
  )

  // Handle --select-1: auto-select if only one match
  if select_1 && app.filtered_count() == 1 {
    match app.get_first_filtered() {
      Some(text) => {
        // Print expected key (empty for auto-select)
        if expect.length() > 0 {
          if print0 {
            @io.print_raw("")
            @io.print_raw("\u0000")
          } else {
            println("")
          }
        }
        // Print query first if requested
        if print_query {
          if print0 {
            @io.print_raw(app.get_query())
            @io.print_raw("\u0000")
          } else {
            println(app.get_query())
          }
        }
        if print0 {
          @io.print_raw(text)
          @io.print_raw("\u0000")
        } else {
          println(text)
        }
      }
      None => ()
    }
    return
  }

  // Handle --exit-0: exit if no matches
  if exit_0 && app.filtered_count() == 0 {
    return
  }

  // Enter alternate screen and enable raw mode
  @io.print_raw("\u001b[?1049h") // Enter alternate screen
  @io.enable_raw_mode()

  // Initial render
  @io.print_raw(app.render())

  // Keep event loop alive (needed for JS target)
  @io.set_idle_handler(fn() { () })

  // Event loop
  @io.start_keypress_listener(fn(key) {
    if key.length() == 0 || not(app.is_running()) {
      return
    }
    let event = @events.parse_input(key)
    app.handle_key(event)
    if app.is_running() {
      @io.print_raw(app.render())
    } else {
      // Exit cleanup
      @io.stop_keypress_listener()
      @io.cleanup_stdin()
      @io.print_raw("\u001b[?1049l") // Leave alternate screen

      // Output result
      match app.get_result() {
        Some(result) => {
          // Write history on successful selection
          let query = app.get_query()
          on_select(query)
          // Print expected key if --expect was used
          let pressed = app.get_pressed_key()
          if expect.length() > 0 {
            if print0 {
              @io.print_raw(pressed)
              @io.print_raw("\u0000")
            } else {
              println(pressed)
            }
          }
          // Print query first if requested
          if print_query {
            if print0 {
              @io.print_raw(query)
              @io.print_raw("\u0000")
            } else {
              println(query)
            }
          }
          if print0 {
            // Use NUL separator for xargs -0
            let lines = split_lines(result)
            for i = 0; i < lines.length(); i = i + 1 {
              @io.print_raw(lines[i])
              @io.print_raw("\u0000")
            }
          } else {
            println(result)
          }
        }
        None => ()
      }
    }
  })
}

///|
/// Reverse an array of items
fn reverse_items(items : Array[@core.Item]) -> Array[@core.Item] {
  let result : Array[@core.Item] = []
  for i = items.length() - 1; i >= 0; i = i - 1 {
    result.push(items[i])
  }
  // Re-assign original indices
  for i = 0; i < result.length(); i = i + 1 {
    result[i] = @core.Item::new(result[i].text, i)
  }
  result
}

///|
/// Split string by newline
fn split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let chars : Array[Char] = s.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '\n' {
      lines.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(chars[i])
    }
  }
  // Add last line if any
  if buf.to_string().length() > 0 {
    lines.push(buf.to_string())
  }
  lines
}
