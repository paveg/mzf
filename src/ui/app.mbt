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
/// Confirm selection
fn App::confirm_selection(self : App) -> Unit {
  if self.filtered.length() > 0 && self.selected_idx < self.filtered.length() {
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
  buf.write_string("_\n")

  // Separator
  buf.write_string(ansi_dim)
  for i = 0; i < self.width - 1; i = i + 1 {
    ignore(i)
    buf.write_string("─")
  }
  buf.write_string(ansi_reset)
  buf.write_string("\n")

  // Render items
  let visible_count = if self.filtered.length() > max_visible {
    max_visible
  } else {
    self.filtered.length()
  }
  for i = 0; i < visible_count; i = i + 1 {
    let result = self.filtered[i]
    let is_selected = i == self.selected_idx
    if is_selected {
      buf.write_string(ansi_reverse)
      buf.write_string(ansi_cyan)
      buf.write_string("> ")
    } else {
      buf.write_string("  ")
    }

    // Highlight matching characters
    buf.write_string(highlight_match_result(result))
    if is_selected {
      buf.write_string(ansi_reset)
    }
    buf.write_string("\n")
  }

  // Fill remaining lines
  for j = visible_count; j < max_visible; j = j + 1 {
    ignore(j)
    buf.write_string("\n")
  }

  // Status line
  buf.write_string(ansi_dim)
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
