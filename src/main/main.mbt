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
  extended? : Bool = false,
  exact? : Bool = false,
  ignore_case? : Bool = false,
  header? : String = "",
  print_query? : Bool = false,
  with_nth? : String = "",
  expect? : String = "",
  ansi? : Bool = false,
  history? : Array[String] = [],
  on_select? : (String) -> Unit = fn(_q) {  },
  border? : String = "none",
  info? : String = "default",
  layout? : String = "default",
  color? : String = "",
  preview? : String = "",
  preview_window? : String = "right:50%",
  fetch_preview? : (String) -> String = fn(_cmd) { "" },
  inline_mode? : Bool = false,
) -> Unit {
  if items.length() == 0 {
    if exit_0 {
      // Exit immediately with no output
      return
    }
    return
  }
  // Calculate row_offset for inline mode (1 = inline mode, 0 = full screen)
  let row_offset = if inline_mode { 1 } else { 0 }
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
    extended~,
    exact~,
    ignore_case~,
    header~,
    with_nth~,
    expect~,
    ansi~,
    history~,
    border~,
    info~,
    layout~,
    color~,
    preview~,
    preview_window~,
    row_offset~,
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

  // Enter raw mode and set up screen
  @io.enable_raw_mode()
  if inline_mode {
    // Inline mode: render at current cursor position
    // Move down to make room and save position
    @io.print_raw("\u001b[0m") // Reset all attributes
    @io.print_raw("\u001b7") // Save cursor position (DECSC)
    // Print newlines to make room for the UI
    for _i = 0; _i < height; _i = _i + 1 {
      @io.print_raw("\n")
    }
    // Move cursor up to the start of our rendering area
    @io.print_raw("\u001b[" + height.to_string() + "A")
    @io.print_raw("\u001b[0G") // Move to column 0
  } else {
    // Full screen mode: use alternate screen buffer
    @io.print_raw("\u001b[?1049h") // Enter alternate screen
    @io.print_raw("\u001b[2J") // Clear entire alternate screen
    @io.print_raw("\u001b[H") // Move to home
    @io.print_raw("\u001b[0m") // Reset all attributes
  }

  // Helper to update preview
  fn update_preview() -> Unit {
    if app.has_preview() && app.preview_needs_update() {
      match app.get_current_item() {
        Some(item) => {
          let cmd = substitute_placeholders(
            app.get_preview_command(),
            item,
            app.get_current_line_num(),
            app.get_query(),
            app.get_marked_items(),
            app.get_marked_indices(),
          )
          let output = fetch_preview(cmd)
          app.set_preview_cache(output)
        }
        None => app.set_preview_cache("(no item selected)")
      }
    }
  }

  // Initial preview fetch
  update_preview()

  // Track if this is the first render (for inline mode cursor positioning)
  let first_render = Ref::new(true)

  // Helper to render with proper cursor positioning for inline mode
  fn do_render() -> Unit {
    if inline_mode && not(first_render.val) {
      // Move cursor to start of rendering area (from prompt position)
      // After render, cursor is at prompt. Move to column 0, then up to start.
      @io.print_raw("\u001b[0G") // Move to column 0
      @io.print_raw("\u001b[" + (height - 1).to_string() + "A") // Move up to start
    }
    first_render.val = false
    @io.print_raw(app.render())
  }

  // Initial render
  do_render()

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
      // Update preview if selection changed
      update_preview()
      do_render()
    } else {
      // Exit cleanup
      @io.stop_keypress_listener()
      @io.cleanup_stdin()
      if inline_mode {
        // Inline mode: clear the rendered area and restore cursor
        // Move to start of our area
        @io.print_raw("\u001b[0G") // Move to column 0
        // Clear each line we used
        for _i = 0; _i < height; _i = _i + 1 {
          @io.print_raw("\u001b[2K") // Clear entire line
          @io.print_raw("\u001b[1B") // Move down
        }
        // Move back up and restore original position
        @io.print_raw("\u001b[" + height.to_string() + "A")
        @io.print_raw("\u001b8") // Restore cursor position (DECRC)
        @io.print_raw("\u001b[0K") // Clear from cursor to end of line
      } else {
        @io.print_raw("\u001b[?1049l") // Leave alternate screen
      }

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
