///|
/// Main application state for mzf
pub struct App {
  mut query : String
  mut selected_idx : Int
  mut running : Bool
  items : Array[@core.Item]
  mut filtered : Array[@core.MatchResult]
  width : Int
  height : Int
  mut result : String?
  // Multi-select: stores original_index of marked items
  mut marked : Array[Int]
}

///|
pub fn App::new(
  items : Array[@core.Item],
  width : Int,
  height : Int,
  initial_query? : String = "",
) -> App {
  let app : App = {
    query: initial_query,
    selected_idx: 0,
    running: true,
    items,
    filtered: [],
    width,
    height,
    result: None,
    marked: [],
  }
  // Apply initial filter
  app.update_filter()
  app
}

///|
/// Update filtered results based on current query
fn App::update_filter(self : App) -> Unit {
  if self.query.length() == 0 {
    // Show all items when query is empty
    self.filtered = self.items.mapi(fn(_i, item) {
      @core.MatchResult::new(item, 0, [])
    })
  } else {
    self.filtered = @core.filter_and_score(self.query, self.items)
  }
  // Reset selection if out of bounds
  if self.selected_idx >= self.filtered.length() {
    self.selected_idx = if self.filtered.length() > 0 {
      self.filtered.length() - 1
    } else {
      0
    }
  }
}

///|
/// Move selection up
fn App::select_up(self : App) -> Unit {
  if self.selected_idx > 0 {
    self.selected_idx = self.selected_idx - 1
  }
}

///|
/// Move selection down
fn App::select_down(self : App) -> Unit {
  if self.selected_idx < self.filtered.length() - 1 {
    self.selected_idx = self.selected_idx + 1
  }
}

///|
/// Toggle mark on current item
fn App::toggle_mark(self : App) -> Unit {
  if self.filtered.length() == 0 {
    return
  }
  let current = self.filtered[self.selected_idx]
  let idx = current.item.original_index
  // Check if already marked
  let mut found = -1
  for i = 0; i < self.marked.length(); i = i + 1 {
    if self.marked[i] == idx {
      found = i
      break
    }
  }
  if found >= 0 {
    // Remove from marked
    let new_marked : Array[Int] = []
    for i = 0; i < self.marked.length(); i = i + 1 {
      if i != found {
        new_marked.push(self.marked[i])
      }
    }
    self.marked = new_marked
  } else {
    // Add to marked
    self.marked.push(idx)
  }
  // Move down after toggle (like fzf)
  self.select_down()
}

///|
/// Check if an item is marked by original_index
fn App::is_marked(self : App, original_index : Int) -> Bool {
  for i = 0; i < self.marked.length(); i = i + 1 {
    if self.marked[i] == original_index {
      return true
    }
  }
  false
}

///|
/// Confirm selection
fn App::confirm_selection(self : App) -> Unit {
  if self.marked.length() > 0 {
    // Return all marked items
    let buf = StringBuilder::new()
    for i = 0; i < self.marked.length(); i = i + 1 {
      let idx = self.marked[i]
      // Find item by original_index
      for j = 0; j < self.items.length(); j = j + 1 {
        if self.items[j].original_index == idx {
          if i > 0 {
            buf.write_string("\n")
          }
          buf.write_string(self.items[j].text)
          break
        }
      }
    }
    self.result = Some(buf.to_string())
  } else if self.filtered.length() > 0 &&
    self.selected_idx < self.filtered.length() {
    // Return current item
    self.result = Some(self.filtered[self.selected_idx].item.text)
  }
  self.running = false
}

///|
/// Cancel and exit
fn App::cancel(self : App) -> Unit {
  self.result = None
  self.running = false
}

///|
/// Handle character input
fn App::handle_char(self : App, c : Char) -> Unit {
  self.query = self.query + c.to_string()
  self.selected_idx = 0
  self.update_filter()
}

///|
/// Handle backspace
fn App::handle_backspace(self : App) -> Unit {
  if self.query.length() > 0 {
    let chars : Array[Char] = self.query.iter().collect()
    let new_len = chars.length() - 1
    let buf = StringBuilder::new()
    for i = 0; i < new_len; i = i + 1 {
      buf.write_char(chars[i])
    }
    self.query = buf.to_string()
    self.selected_idx = 0
    self.update_filter()
  }
}

///|
/// Clear input
fn App::clear_input(self : App) -> Unit {
  self.query = ""
  self.selected_idx = 0
  self.update_filter()
}

///|
/// Handle key event
pub fn App::handle_key(self : App, event : @events.InputEvent) -> Unit {
  match event {
    @events.InputEvent::Key(key_event) =>
      match key_event {
        @events.KeyEvent::Special(@events.SpecialKey::Escape, _) =>
          self.cancel()
        @events.KeyEvent::Special(@events.SpecialKey::Enter, _) =>
          self.confirm_selection()
        @events.KeyEvent::Special(@events.SpecialKey::Up, _) => self.select_up()
        @events.KeyEvent::Special(@events.SpecialKey::Down, _) =>
          self.select_down()
        @events.KeyEvent::Special(@events.SpecialKey::Tab, _) =>
          self.toggle_mark()
        @events.KeyEvent::Special(@events.SpecialKey::Backspace, _) =>
          self.handle_backspace()
        @events.KeyEvent::Char(c, @events.KeyModifier::Ctrl) =>
          if c == 'c' {
            self.cancel()
          } else if c == 'p' {
            self.select_up()
          } else if c == 'n' {
            self.select_down()
          } else if c == 'u' {
            self.clear_input()
          }
        @events.KeyEvent::Char(c, @events.KeyModifier::None)
        | @events.KeyEvent::Char(c, @events.KeyModifier::Shift) =>
          self.handle_char(c)
        _ => ()
      }
    _ => ()
  }
}

///|
/// Render the UI
pub fn App::render(self : App) -> String {
  let buf = StringBuilder::new()
  let max_visible = self.height - 3 // Reserve lines for prompt and status

  // Hide cursor and move to top
  buf.write_string("\u001b[?25l") // Hide cursor
  buf.write_string("\u001b[H") // Move to home
  buf.write_string("\u001b[J") // Clear from cursor to end

  // Render prompt line
  buf.write_string(ansi_yellow)
  buf.write_string("> ")
  buf.write_string(ansi_reset)
  buf.write_string(self.query)
  buf.write_string("_\r\n")

  // Separator
  buf.write_string(ansi_dim)
  for i = 0; i < self.width - 1; i = i + 1 {
    ignore(i)
    buf.write_string("─")
  }
  buf.write_string(ansi_reset)
  buf.write_string("\r\n")

  // Render items
  let visible_count = if self.filtered.length() > max_visible {
    max_visible
  } else {
    self.filtered.length()
  }
  for i = 0; i < visible_count; i = i + 1 {
    let result = self.filtered[i]
    let is_cursor = i == self.selected_idx
    let is_marked = self.is_marked(result.item.original_index)

    // Marker column
    if is_marked {
      buf.write_string(ansi_green)
      buf.write_string("*")
      buf.write_string(ansi_reset)
    } else {
      buf.write_string(" ")
    }

    // Selection indicator
    if is_cursor {
      buf.write_string(ansi_reverse)
      buf.write_string(ansi_cyan)
      buf.write_string("> ")
    } else {
      buf.write_string("  ")
    }

    // For cursor items, don't highlight matches (reverse video is enough)
    // For non-cursor items, highlight matching characters
    if is_cursor {
      buf.write_string(result.item.text)
      buf.write_string(ansi_reset)
    } else {
      buf.write_string(highlight_match_result(result))
    }
    buf.write_string("\r\n")
  }

  // Fill remaining lines
  for j = visible_count; j < max_visible; j = j + 1 {
    ignore(j)
    buf.write_string("\r\n")
  }

  // Status line
  buf.write_string(ansi_dim)
  if self.marked.length() > 0 {
    buf.write_string(self.marked.length().to_string())
    buf.write_string("/")
  }
  buf.write_string(self.filtered.length().to_string())
  buf.write_string("/")
  buf.write_string(self.items.length().to_string())
  buf.write_string(ansi_reset)

  // Show cursor at query position
  let cursor_row = 1
  let cursor_col = 3 + self.query.length()
  buf.write_string("\u001b[")
  buf.write_string(cursor_row.to_string())
  buf.write_string(";")
  buf.write_string(cursor_col.to_string())
  buf.write_string("H")
  buf.write_string("\u001b[?25h") // Show cursor
  buf.to_string()
}

///|
/// Check if app is still running
pub fn App::is_running(self : App) -> Bool {
  self.running
}

///|
/// Get result
pub fn App::get_result(self : App) -> String? {
  self.result
}
