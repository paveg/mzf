///|
/// Split string by delimiter
fn split_by_delimiter(text : String, delimiter : String) -> Array[String] {
  let fields : Array[String] = []
  let delim_char = delimiter.iter().collect()[0] // Assume single char delimiter
  let chars : Array[Char] = text.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == delim_char {
      fields.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(chars[i])
    }
  }
  // Add last field
  fields.push(buf.to_string())
  fields
}

///|
/// Parse nth indices (e.g., "1,2,3" or "-1")
fn parse_nth_indices(nth : String) -> Array[Int] {
  let indices : Array[Int] = []
  let chars : Array[Char] = nth.iter().collect()
  let buf = StringBuilder::new()
  let mut negative = false
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == ',' {
      if buf.to_string().length() > 0 {
        let val = parse_nth_int(buf.to_string())
        indices.push(if negative { -val } else { val })
      }
      buf.reset()
      negative = false
    } else if c == '-' {
      negative = true
    } else if c >= '0' && c <= '9' {
      buf.write_char(c)
    }
  }
  // Add last number
  if buf.to_string().length() > 0 {
    let val = parse_nth_int(buf.to_string())
    indices.push(if negative { -val } else { val })
  }
  indices
}

///|
/// Parse integer from string
fn parse_nth_int(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

///|
/// Extract fields by indices (1-indexed, negative from end)
fn extract_fields(fields : Array[String], indices : Array[Int]) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < indices.length(); i = i + 1 {
    let idx = indices[i]
    let actual_idx = if idx < 0 {
      fields.length() + idx // -1 means last field
    } else {
      idx - 1 // 1-indexed to 0-indexed
    }
    if actual_idx >= 0 && actual_idx < fields.length() {
      if i > 0 {
        buf.write_string(" ")
      }
      buf.write_string(fields[actual_idx])
    }
  }
  buf.to_string()
}

///|
/// Filter with nth field matching
fn filter_with_nth(
  pattern : String,
  items : Array[@core.Item],
  nth : String,
  delimiter : String,
  no_sort : Bool,
) -> Array[@core.MatchResult] {
  let indices = parse_nth_indices(nth)
  let results : Array[@core.MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    let fields = split_by_delimiter(item.text, delimiter)
    let match_text = extract_fields(fields, indices)
    match @core.fuzzy_match(pattern, match_text) {
      Some((score, positions)) =>
        results.push(@core.MatchResult::new(item, score, positions))
      None => ()
    }
  }
  if not(no_sort) {
    results.sort_by(fn(a, b) { b.score - a.score })
  }
  results
}

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
  // Display options
  reverse : Bool // Display from top to bottom
  prompt : String // Input prompt string
  pointer : String // Pointer/cursor string
  marker : String // Marker string for multi-select
  multi : Bool // Enable multi-select mode (-m)
  // Behavior options
  cycle : Bool // Enable cyclic scroll
  no_sort : Bool // Don't sort results by score
  nth : String // Field indices for matching
  delimiter : String // Field delimiter
  // Search options
  exact : Bool // Exact match mode
  ignore_case : Bool // Force case insensitive
  // Display options
  header : String // Header text
  with_nth : String // Field indices for display transformation
  // Key handling
  expect : String // Expected keys to abort
  mut pressed_key : String // The expected key that was pressed (empty if regular selection)
  // Advanced options
  ansi : Bool // Enable ANSI color processing
  // History
  history : Array[String] // History entries (most recent last)
  mut history_idx : Int // Current position in history (-1 = current query)
  mut saved_query : String // Query saved when entering history navigation
}

///|
pub fn App::new(
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
  exact? : Bool = false,
  ignore_case? : Bool = false,
  header? : String = "",
  with_nth? : String = "",
  expect? : String = "",
  ansi? : Bool = false,
  history? : Array[String] = [],
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
    reverse,
    prompt,
    pointer,
    marker,
    multi,
    cycle,
    no_sort,
    nth,
    delimiter,
    exact,
    ignore_case,
    header,
    with_nth,
    expect,
    pressed_key: "",
    ansi,
    history,
    history_idx: -1,
    saved_query: "",
  }
  // Apply initial filter
  app.update_filter()
  app
}

///|
/// Convert a KeyEvent to a key name string (for --expect)
fn key_event_to_name(event : @events.KeyEvent) -> String {
  match event {
    @events.KeyEvent::Special(@events.SpecialKey::Enter, _) => "enter"
    @events.KeyEvent::Special(@events.SpecialKey::Tab, _) => "tab"
    @events.KeyEvent::Special(@events.SpecialKey::Escape, _) => "esc"
    @events.KeyEvent::Special(@events.SpecialKey::Up, _) => "up"
    @events.KeyEvent::Special(@events.SpecialKey::Down, _) => "down"
    @events.KeyEvent::Special(@events.SpecialKey::Left, _) => "left"
    @events.KeyEvent::Special(@events.SpecialKey::Right, _) => "right"
    @events.KeyEvent::Special(@events.SpecialKey::Backspace, _) => "backspace"
    @events.KeyEvent::Special(@events.SpecialKey::Delete, _) => "delete"
    @events.KeyEvent::Special(@events.SpecialKey::Home, _) => "home"
    @events.KeyEvent::Special(@events.SpecialKey::End, _) => "end"
    @events.KeyEvent::Special(@events.SpecialKey::PageUp, _) => "page-up"
    @events.KeyEvent::Special(@events.SpecialKey::PageDown, _) => "page-down"
    @events.KeyEvent::Char(c, @events.KeyModifier::Ctrl) =>
      "ctrl-" + c.to_string()
    @events.KeyEvent::Char(c, @events.KeyModifier::Alt) =>
      "alt-" + c.to_string()
    @events.KeyEvent::Char(c, _) => c.to_string()
    _ => ""
  }
}

///|
/// Check if a key name matches any expected keys
fn App::is_expected_key(self : App, key_name : String) -> Bool {
  if self.expect.length() == 0 {
    return false
  }
  // Split expect string by comma and check each
  let expected_keys = split_by_comma(self.expect)
  for expected in expected_keys {
    if expected == key_name {
      return true
    }
  }
  false
}

///|
/// Split string by comma
fn split_by_comma(s : String) -> Array[String] {
  let result : Array[String] = []
  let chars : Array[Char] = s.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == ',' {
      result.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(chars[i])
    }
  }
  if buf.to_string().length() > 0 {
    result.push(buf.to_string())
  }
  result
}

///|
/// Get the pressed key (for --expect output)
pub fn App::get_pressed_key(self : App) -> String {
  self.pressed_key
}

///|
/// Handle expected key press - confirm selection with key name
fn App::handle_expect_key(self : App, key_name : String) -> Unit {
  self.pressed_key = key_name
  self.confirm_selection()
}

///|
/// Create items with ANSI-stripped text for matching
fn create_ansi_stripped_items(items : Array[@core.Item]) -> Array[@core.Item] {
  let stripped : Array[@core.Item] = []
  for i = 0; i < items.length(); i = i + 1 {
    let text = @core.strip_ansi(items[i].text)
    stripped.push(@core.Item::new(text, items[i].original_index))
  }
  stripped
}

///|
/// Map match results back to original items (for ANSI mode)
fn map_results_to_original(
  results : Array[@core.MatchResult],
  original_items : Array[@core.Item],
) -> Array[@core.MatchResult] {
  let mapped : Array[@core.MatchResult] = []
  for i = 0; i < results.length(); i = i + 1 {
    let r = results[i]
    // Find original item by original_index
    for j = 0; j < original_items.length(); j = j + 1 {
      if original_items[j].original_index == r.item.original_index {
        mapped.push(
          @core.MatchResult::new(original_items[j], r.score, r.match_positions),
        )
        break
      }
    }
  }
  mapped
}

///|
/// Update filtered results based on current query
fn App::update_filter(self : App) -> Unit {
  // For ANSI mode, create stripped items for matching
  let match_items = if self.ansi {
    create_ansi_stripped_items(self.items)
  } else {
    self.items
  }
  let results = if self.query.length() == 0 {
    // Show all items when query is empty
    match_items.mapi(fn(_i, item) { @core.MatchResult::new(item, 0, []) })
  } else if self.nth.length() > 0 && self.delimiter.length() > 0 {
    // Field-specific matching with nth
    filter_with_nth(
      self.query,
      match_items,
      self.nth,
      self.delimiter,
      self.no_sort,
    )
  } else if self.exact {
    // Exact substring matching
    if self.no_sort {
      @core.filter_exact_no_sort(self.query, match_items, self.ignore_case)
    } else {
      @core.filter_exact(self.query, match_items, self.ignore_case)
    }
  } else if self.ignore_case {
    // Fuzzy matching with forced case insensitivity
    if self.no_sort {
      @core.filter_without_sort_ignore_case(self.query, match_items)
    } else {
      @core.filter_and_score_ignore_case(self.query, match_items)
    }
  } else if self.no_sort {
    // Filter without sorting (keep original order)
    @core.filter_without_sort(self.query, match_items)
  } else {
    @core.filter_and_score(self.query, match_items)
  }

  // Map results back to original items for ANSI mode
  self.filtered = if self.ansi {
    map_results_to_original(results, self.items)
  } else {
    results
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
  } else if self.cycle && self.filtered.length() > 0 {
    // Wrap to bottom
    self.selected_idx = self.filtered.length() - 1
  }
}

///|
/// Move selection down
fn App::select_down(self : App) -> Unit {
  if self.selected_idx < self.filtered.length() - 1 {
    self.selected_idx = self.selected_idx + 1
  } else if self.cycle && self.filtered.length() > 0 {
    // Wrap to top
    self.selected_idx = 0
  }
}

///|
/// Toggle mark on current item (only works when multi-select is enabled)
fn App::toggle_mark(self : App) -> Unit {
  // Multi-select must be enabled with -m flag
  if not(self.multi) {
    return
  }
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
  self.history_idx = -1 // Reset history navigation
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
    self.history_idx = -1 // Reset history navigation
    self.update_filter()
  }
}

///|
/// Clear input
fn App::clear_input(self : App) -> Unit {
  self.query = ""
  self.selected_idx = 0
  self.history_idx = -1 // Reset history navigation
  self.update_filter()
}

///|
/// Navigate to previous history entry (Ctrl+P with history)
fn App::history_prev(self : App) -> Unit {
  if self.history.length() == 0 {
    return
  }
  // Save current query when entering history
  if self.history_idx == -1 {
    self.saved_query = self.query
  }
  // Move to previous (older) entry
  if self.history_idx < self.history.length() - 1 {
    self.history_idx = self.history_idx + 1
    // History is stored with most recent last, so index from end
    let entry_idx = self.history.length() - 1 - self.history_idx
    self.query = self.history[entry_idx]
    self.selected_idx = 0
    self.update_filter()
  }
}

///|
/// Navigate to next history entry (Ctrl+N with history)
fn App::history_next(self : App) -> Unit {
  if self.history.length() == 0 {
    return
  }
  if self.history_idx > 0 {
    self.history_idx = self.history_idx - 1
    let entry_idx = self.history.length() - 1 - self.history_idx
    self.query = self.history[entry_idx]
    self.selected_idx = 0
    self.update_filter()
  } else if self.history_idx == 0 {
    // Return to current (unsaved) query
    self.history_idx = -1
    self.query = self.saved_query
    self.selected_idx = 0
    self.update_filter()
  }
}

///|
/// Check if history navigation is active
pub fn App::has_history(self : App) -> Bool {
  self.history.length() > 0
}

///|
/// Handle key event
pub fn App::handle_key(self : App, event : @events.InputEvent) -> Unit {
  match event {
    @events.InputEvent::Key(key_event) => {
      // Check for expected keys first
      let key_name = key_event_to_name(key_event)
      if self.is_expected_key(key_name) {
        self.handle_expect_key(key_name)
        return
      }
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
            // Ctrl+P: history prev (if available), otherwise select up
            if self.has_history() {
              self.history_prev()
            } else {
              self.select_up()
            }
          } else if c == 'n' {
            // Ctrl+N: history next (if available), otherwise select down
            if self.has_history() {
              self.history_next()
            } else {
              self.select_down()
            }
          } else if c == 'u' {
            self.clear_input()
          }
        @events.KeyEvent::Char(c, @events.KeyModifier::None)
        | @events.KeyEvent::Char(c, @events.KeyModifier::Shift) =>
          self.handle_char(c)
        _ => ()
      }
    }
    _ => ()
  }
}

///|
/// Render a single item line

///|
/// Get display text for an item (applies with_nth transformation if set)
fn App::get_display_text(self : App, text : String) -> String {
  if self.with_nth.length() > 0 && self.delimiter.length() > 0 {
    let fields = split_by_delimiter(text, self.delimiter)
    let indices = parse_nth_indices(self.with_nth)
    extract_fields(fields, indices)
  } else {
    text
  }
}

///|
fn App::render_item(self : App, buf : StringBuilder, idx : Int) -> Unit {
  let result = self.filtered[idx]
  let is_cursor = idx == self.selected_idx
  let is_marked = self.is_marked(result.item.original_index)

  // Marker column
  if is_marked {
    buf.write_string(ansi_green)
    buf.write_string(self.marker)
    buf.write_string(ansi_reset)
  } else {
    // Pad with spaces to match marker width
    for k = 0; k < string_width(self.marker); k = k + 1 {
      ignore(k)
      buf.write_string(" ")
    }
  }

  // Selection indicator
  if is_cursor {
    buf.write_string(ansi_reverse)
    buf.write_string(ansi_cyan)
    buf.write_string(self.pointer)
  } else {
    // Pad with spaces to match pointer width
    for k = 0; k < string_width(self.pointer); k = k + 1 {
      ignore(k)
      buf.write_string(" ")
    }
  }

  // Get display text (apply with_nth if set)
  let display_text = self.get_display_text(result.item.text)

  // For cursor items, don't highlight matches (reverse video is enough)
  // For non-cursor items, highlight matching characters
  if is_cursor {
    buf.write_string(display_text)
    buf.write_string(ansi_reset)
    // Note: highlighting won't work correctly with with_nth since positions are for original text
    // For simplicity, just display without highlighting when with_nth is used
  } else if self.with_nth.length() > 0 {
    buf.write_string(display_text)
  } else {
    buf.write_string(highlight_match_result(result))
  }
  buf.write_string("\r\n")
}

///|
/// Get display width of a string (simple: 1 per char)
fn string_width(s : String) -> Int {
  s.iter().count()
}

///|
/// Render the UI
pub fn App::render(self : App) -> String {
  let buf = StringBuilder::new()
  // Reserve lines for prompt, status, and header if present
  let header_lines = if self.header.length() > 0 { 1 } else { 0 }
  let max_visible = self.height - 3 - header_lines

  // Hide cursor and move to top
  buf.write_string("\u001b[?25l") // Hide cursor
  buf.write_string("\u001b[H") // Move to home
  buf.write_string("\u001b[J") // Clear from cursor to end
  let visible_count = if self.filtered.length() > max_visible {
    max_visible
  } else {
    self.filtered.length()
  }
  if self.reverse {
    // Reverse mode: status at top, items bottom-to-top, prompt at bottom
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
    buf.write_string("\r\n")

    // Header (if present)
    if self.header.length() > 0 {
      buf.write_string(ansi_magenta)
      buf.write_string(self.header)
      buf.write_string(ansi_reset)
      buf.write_string("\r\n")
    }

    // Fill empty lines first
    for j = visible_count; j < max_visible; j = j + 1 {
      ignore(j)
      buf.write_string("\r\n")
    }

    // Render items in reverse order (last item first)
    for i = visible_count - 1; i >= 0; i = i - 1 {
      self.render_item(buf, i)
    }

    // Separator
    buf.write_string(ansi_dim)
    for i = 0; i < self.width - 1; i = i + 1 {
      ignore(i)
      buf.write_string("─")
    }
    buf.write_string(ansi_reset)
    buf.write_string("\r\n")

    // Render prompt line at bottom
    buf.write_string(ansi_yellow)
    buf.write_string(self.prompt)
    buf.write_string(ansi_reset)
    buf.write_string(self.query)
    buf.write_string("_")

    // Show cursor at query position (bottom line in reverse mode)
    let cursor_row = self.height
    let cursor_col = string_width(self.prompt) + 1 + self.query.length()
    buf.write_string("\u001b[")
    buf.write_string(cursor_row.to_string())
    buf.write_string(";")
    buf.write_string(cursor_col.to_string())
    buf.write_string("H")
    buf.write_string("\u001b[?25h") // Show cursor
  } else {
    // Normal mode: prompt at top, items top-to-bottom, status at bottom
    // Render prompt line
    buf.write_string(ansi_yellow)
    buf.write_string(self.prompt)
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

    // Header (if present)
    if self.header.length() > 0 {
      buf.write_string(ansi_magenta)
      buf.write_string(self.header)
      buf.write_string(ansi_reset)
      buf.write_string("\r\n")
    }

    // Render items
    for i = 0; i < visible_count; i = i + 1 {
      self.render_item(buf, i)
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
    let cursor_col = string_width(self.prompt) + 1 + self.query.length()
    buf.write_string("\u001b[")
    buf.write_string(cursor_row.to_string())
    buf.write_string(";")
    buf.write_string(cursor_col.to_string())
    buf.write_string("H")
    buf.write_string("\u001b[?25h") // Show cursor
  }
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

///|
/// Get current query string
pub fn App::get_query(self : App) -> String {
  self.query
}

///|
/// Get number of filtered items
pub fn App::filtered_count(self : App) -> Int {
  self.filtered.length()
}

///|
/// Get first filtered item text (for --select-1)
pub fn App::get_first_filtered(self : App) -> String? {
  if self.filtered.length() > 0 {
    Some(self.filtered[0].item.text)
  } else {
    None
  }
}
