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
  let delim_char = delimiter.iter().collect()[0]
  let results : Array[@core.MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    let fields = @core.split_by_char(item.text, delim_char)
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
  extended : Bool // Extended search mode
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
  // Display style
  border : String // Border style (none, rounded, sharp, horizontal)
  info : String // Info line style (default, hidden, inline)
  layout : String // Layout (default, reverse, reverse-list)
  colors : ColorScheme // Color scheme for UI elements
  // Preview
  preview_command : String // Preview command template
  preview_window : String // Preview window spec (right:50%, bottom:40%)
  mut preview_cache : String // Cached preview output
  mut preview_item_idx : Int // Index of item preview was generated for (-1 = none)
  // Inline mode
  row_offset : Int // Row offset for inline mode (0 for full screen)
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
  extended? : Bool = false,
  exact? : Bool = false,
  ignore_case? : Bool = false,
  header? : String = "",
  with_nth? : String = "",
  expect? : String = "",
  ansi? : Bool = false,
  history? : Array[String] = [],
  border? : String = "none",
  info? : String = "default",
  layout? : String = "default",
  color? : String = "",
  preview? : String = "",
  preview_window? : String = "right:50%",
  row_offset? : Int = 0,
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
    extended,
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
    border,
    info,
    layout,
    colors: ColorScheme::parse(color),
    preview_command: preview,
    preview_window,
    preview_cache: "",
    preview_item_idx: -1,
    row_offset,
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
  let expected_keys = @core.split_by_comma(self.expect)
  for expected in expected_keys {
    if expected == key_name {
      return true
    }
  }
  false
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
  // Determine case sensitivity (smart case: sensitive if query has uppercase)
  let case_sensitive = if self.ignore_case {
    false
  } else {
    @core.has_uppercase_query(self.query)
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
  } else if self.extended {
    // Extended search mode (^, $, ', !)
    if self.no_sort {
      @core.filter_extended_no_sort(self.query, match_items, case_sensitive)
    } else {
      @core.filter_extended(self.query, match_items, case_sensitive)
    }
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
/// Calculate the number of visible items (page size)
fn App::get_page_size(self : App) -> Int {
  let header_lines = @core.count_lines(self.header)
  let info_lines = if self.info == "default" { 1 } else { 0 }
  let top_line = 1 // Always have top border or spacer line
  let bottom_line = if self.border != "none" { 1 } else { 0 }
  let page_size = self.height -
    2 -
    header_lines -
    info_lines -
    top_line -
    bottom_line
  if page_size < 1 {
    1
  } else {
    page_size
  }
}

///|
/// Move selection up by one page
fn App::select_page_up(self : App) -> Unit {
  let page_size = self.get_page_size()
  let new_idx = self.selected_idx - page_size
  if new_idx >= 0 {
    self.selected_idx = new_idx
  } else if self.cycle && self.filtered.length() > 0 {
    // Wrap to near bottom
    let target = self.filtered.length() - 1 + new_idx + 1
    self.selected_idx = if target >= 0 { target } else { 0 }
  } else {
    self.selected_idx = 0
  }
}

///|
/// Move selection down by one page
fn App::select_page_down(self : App) -> Unit {
  let page_size = self.get_page_size()
  let max_idx = self.filtered.length() - 1
  let new_idx = self.selected_idx + page_size
  if new_idx <= max_idx {
    self.selected_idx = new_idx
  } else if self.cycle && self.filtered.length() > 0 {
    // Wrap to near top
    let overflow = new_idx - max_idx - 1
    self.selected_idx = if overflow < self.filtered.length() {
      overflow
    } else {
      max_idx
    }
  } else {
    self.selected_idx = max_idx
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
        @events.KeyEvent::Special(@events.SpecialKey::PageUp, _) =>
          self.select_page_up()
        @events.KeyEvent::Special(@events.SpecialKey::PageDown, _) =>
          self.select_page_down()
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
/// Render header lines (handles multi-line headers properly)
fn App::render_header(self : App, buf : StringBuilder) -> Unit {
  if self.header.length() == 0 {
    return
  }
  let header_chars : Array[Char] = self.header.iter().collect()
  let line_buf = StringBuilder::new()
  for i = 0; i < header_chars.length(); i = i + 1 {
    if header_chars[i] == '\n' {
      // Output the accumulated line
      buf.write_string(self.colors.header)
      buf.write_string(line_buf.to_string())
      buf.write_string(ansi_reset)
      buf.write_string("\u001b[K\r\n") // Clear to end of line
      line_buf.reset()
    } else if header_chars[i] != '\r' {
      line_buf.write_char(header_chars[i])
    }
  }
  // Output last line if any
  let last_line = line_buf.to_string()
  if last_line.length() > 0 {
    buf.write_string(self.colors.header)
    buf.write_string(last_line)
    buf.write_string(ansi_reset)
    buf.write_string("\u001b[K\r\n")
  }
}

///|
/// Render a single item line

///|
/// Get display text for an item (applies with_nth transformation if set)
fn App::get_display_text(self : App, text : String) -> String {
  if self.with_nth.length() > 0 && self.delimiter.length() > 0 {
    let delim_char = self.delimiter.iter().collect()[0]
    let fields = @core.split_by_char(text, delim_char)
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
    buf.write_string(self.colors.marker)
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
    buf.write_string(self.colors.pointer)
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
    buf.write_string(
      highlight_text(result.item.text, result.match_positions, self.colors.hl),
    )
  }
  buf.write_string("\u001b[K") // Clear to end of line
  buf.write_string("\r\n")
}

///|
/// Get display width of a string (simple: 1 per char)
fn string_width(s : String) -> Int {
  s.iter().count()
}

///|
/// Get border characters based on style
fn get_border_chars(
  style : String,
) -> (String, String, String, String, String, String) {
  // Returns (top_left, top_right, bottom_left, bottom_right, horizontal, vertical)
  match style {
    "rounded" => ("╭", "╮", "╰", "╯", "─", "│")
    "sharp" => ("┌", "┐", "└", "┘", "─", "│")
    "horizontal" => ("─", "─", "─", "─", "─", " ")
    _ => ("", "", "", "", "", "") // none
  }
}

///|
/// Render info line (match count)
fn App::render_info(self : App, buf : StringBuilder) -> Unit {
  if self.info == "hidden" {
    return
  }
  buf.write_string(self.colors.info)
  if self.marked.length() > 0 {
    buf.write_string(self.marked.length().to_string())
    buf.write_string("/")
  }
  buf.write_string(self.filtered.length().to_string())
  buf.write_string("/")
  buf.write_string(self.items.length().to_string())
  buf.write_string(ansi_reset)
  buf.write_string("\u001b[K") // Clear to end of line
}

///|
/// Render prompt line with optional inline info
fn App::render_prompt_line(self : App, buf : StringBuilder) -> Unit {
  buf.write_string(self.colors.prompt)
  buf.write_string(self.prompt)
  buf.write_string(ansi_reset)
  // Query text uses explicit foreground color
  buf.write_string(self.colors.fg)
  buf.write_string(self.query)
  buf.write_string(ansi_reset)
  buf.write_string(ansi_dim)
  buf.write_string("_")
  buf.write_string(ansi_reset)
  // Add inline info after cursor if enabled
  if self.info == "inline" {
    buf.write_string(" ")
    self.render_info(buf)
  }
  buf.write_string("\u001b[K") // Clear to end of line
}

///|
/// Render separator line (optionally with border style)
fn App::render_separator(self : App, buf : StringBuilder) -> Unit {
  let (_, _, _, _, h_char, _) = get_border_chars(self.border)
  let sep_char = if h_char.length() > 0 { h_char } else { "─" }
  buf.write_string(self.colors.border)
  for i = 0; i < self.width - 1; i = i + 1 {
    ignore(i)
    buf.write_string(sep_char)
  }
  buf.write_string(ansi_reset)
  buf.write_string("\u001b[K") // Clear to end of line
}

///|
/// Render top border line
fn App::render_top_border(self : App, buf : StringBuilder) -> Unit {
  if self.border == "none" {
    return
  }
  let (tl, tr, _, _, h_char, _) = get_border_chars(self.border)
  buf.write_string(self.colors.border)
  if self.border == "horizontal" {
    for i = 0; i < self.width - 1; i = i + 1 {
      ignore(i)
      buf.write_string(h_char)
    }
  } else {
    // rounded or sharp
    buf.write_string(tl)
    for i = 0; i < self.width - 3; i = i + 1 {
      ignore(i)
      buf.write_string(h_char)
    }
    buf.write_string(tr)
  }
  buf.write_string(ansi_reset)
  buf.write_string("\r\n")
}

///|
/// Render bottom border line
fn App::render_bottom_border(self : App, buf : StringBuilder) -> Unit {
  if self.border == "none" {
    return
  }
  let (_, _, bl, br, h_char, _) = get_border_chars(self.border)
  buf.write_string(self.colors.border)
  if self.border == "horizontal" {
    for i = 0; i < self.width - 1; i = i + 1 {
      ignore(i)
      buf.write_string(h_char)
    }
  } else {
    // rounded or sharp
    buf.write_string(bl)
    for i = 0; i < self.width - 3; i = i + 1 {
      ignore(i)
      buf.write_string(h_char)
    }
    buf.write_string(br)
  }
  buf.write_string(ansi_reset)
}

///|
/// Parse preview window spec and return (position, size_percent)
fn parse_preview_spec(spec : String) -> (String, Int) {
  let chars : Array[Char] = spec.iter().collect()
  let pos_buf = StringBuilder::new()
  let size_buf = StringBuilder::new()
  let mut in_size = false
  for c in chars {
    if c == ':' {
      in_size = true
    } else if in_size {
      if c >= '0' && c <= '9' {
        size_buf.write_char(c)
      }
    } else {
      pos_buf.write_char(c)
    }
  }
  let position = pos_buf.to_string()
  let size_str = size_buf.to_string()
  let mut size = 50
  if size_str.length() > 0 {
    let mut result = 0
    for c in size_str {
      if c >= '0' && c <= '9' {
        result = result * 10 + (c.to_int() - '0'.to_int())
      }
    }
    size = result
  }
  (position, size)
}

///|
/// Split preview content into lines with wrapping
fn split_preview_lines(content : String, max_width : Int) -> Array[String] {
  let lines : Array[String] = []
  let chars : Array[Char] = content.iter().collect()
  let len = chars.length()
  let line_buf = StringBuilder::new()
  let mut col = 0
  let mut i = 0
  while i < len {
    let c = chars[i]
    if c == '\n' {
      lines.push(line_buf.to_string())
      line_buf.reset()
      col = 0
      i = i + 1
    } else if c == '\r' {
      // Skip CR
      i = i + 1
    } else if c == '\u001b' {
      // ANSI escape sequence - include in output but don't count width
      line_buf.write_char(c)
      i = i + 1
      if i < len && chars[i] == '[' {
        // CSI sequence: ESC [ ... final_byte
        line_buf.write_char(chars[i])
        i = i + 1
        // Read parameter and intermediate bytes until final byte
        while i < len {
          let ch = chars[i]
          line_buf.write_char(ch)
          i = i + 1
          let code = ch.to_uint()
          if code >= 0x40 && code <= 0x7E {
            // Final byte found
            break
          }
        }
      } else if i < len {
        // Non-CSI escape, include next char
        line_buf.write_char(chars[i])
        i = i + 1
      }
    } else if c == '\t' {
      // Expand tab to spaces (align to next 8-column boundary)
      let tab_width = 8
      let spaces_to_add = tab_width - col % tab_width
      for _j = 0; _j < spaces_to_add; _j = _j + 1 {
        if col >= max_width {
          lines.push(line_buf.to_string())
          line_buf.reset()
          col = 0
        }
        line_buf.write_char(' ')
        col = col + 1
      }
      i = i + 1
    } else {
      line_buf.write_char(c)
      col = col + 1
      i = i + 1
      if col >= max_width {
        lines.push(line_buf.to_string())
        line_buf.reset()
        col = 0
      }
    }
  }
  let last = line_buf.to_string()
  if last.length() > 0 {
    lines.push(last)
  }
  lines
}

///|
/// Truncate string to specified width (simple, non-ANSI)
fn truncate_to_width(s : String, max_width : Int) -> String {
  let chars : Array[Char] = s.iter().collect()
  if chars.length() <= max_width {
    return s
  }
  let buf = StringBuilder::new()
  for i = 0; i < max_width; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

///|
/// Calculate visible width of a string (excluding ANSI escape codes)
fn visible_width(s : String) -> Int {
  let chars : Array[Char] = s.iter().collect()
  let len = chars.length()
  let mut width = 0
  let mut i = 0
  while i < len {
    if chars[i] == '\u001b' {
      // Skip ANSI escape sequence
      i = i + 1
      if i < len && chars[i] == '[' {
        i = i + 1
        while i < len {
          let code = chars[i].to_uint()
          i = i + 1
          if code >= 0x40 && code <= 0x7E {
            break
          }
        }
      } else if i < len {
        i = i + 1
      }
    } else {
      width = width + 1
      i = i + 1
    }
  }
  width
}

///|
/// Truncate string to specified visible width (ANSI-aware)
/// Preserves ANSI codes but truncates based on visible characters
fn truncate_to_visible_width(s : String, max_width : Int) -> String {
  let chars : Array[Char] = s.iter().collect()
  let len = chars.length()
  let buf = StringBuilder::new()
  let mut width = 0
  let mut i = 0
  while i < len && width < max_width {
    if chars[i] == '\u001b' {
      // Include entire ANSI escape sequence
      buf.write_char(chars[i])
      i = i + 1
      if i < len && chars[i] == '[' {
        buf.write_char(chars[i])
        i = i + 1
        while i < len {
          let ch = chars[i]
          buf.write_char(ch)
          i = i + 1
          let code = ch.to_uint()
          if code >= 0x40 && code <= 0x7E {
            break
          }
        }
      } else if i < len {
        buf.write_char(chars[i])
        i = i + 1
      }
    } else {
      buf.write_char(chars[i])
      width = width + 1
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// Check if layout should show prompt at bottom
fn App::is_prompt_at_bottom(self : App) -> Bool {
  self.layout == "reverse" || self.reverse
}

///|
/// Check if items should be rendered in reverse display order
fn App::is_items_reversed(self : App) -> Bool {
  self.layout == "reverse" || self.layout == "reverse-list" || self.reverse
}

///|
/// Render with preview pane (split view)
fn App::render_with_preview(self : App) -> String {
  let buf = StringBuilder::new()
  let (position, size_percent) = parse_preview_spec(self.preview_window)

  // Minimum widths for usable display
  let min_main_width = 20
  let min_preview_width = 10

  // Calculate pane dimensions
  let is_right = position == "right" || position == ""
  let raw_preview_width = if is_right {
    self.width * size_percent / 100
  } else {
    self.width - 1 // bottom uses full width
  }
  // Enforce minimum widths
  let preview_width = if is_right {
    let max_preview = self.width - min_main_width - 1
    if raw_preview_width > max_preview {
      if max_preview > min_preview_width {
        max_preview
      } else {
        min_preview_width
      }
    } else if raw_preview_width < min_preview_width {
      min_preview_width
    } else {
      raw_preview_width
    }
  } else {
    raw_preview_width
  }
  let main_width = if is_right {
    self.width - preview_width - 1
  } else {
    self.width - 1
  } // -1 for border

  // Calculate heights
  let preview_height = if is_right {
    self.height - 2 // full height minus borders
  } else {
    self.height * size_percent / 100
  }
  let main_height = if is_right {
    self.height - 2
  } else {
    self.height - preview_height - 1
  }

  // Prepare preview lines
  let preview_content_width = if is_right {
    preview_width - 2
  } else {
    self.width - 2
  }
  let preview_lines = split_preview_lines(
    self.preview_cache,
    preview_content_width,
  )
  let max_preview_lines = if is_right {
    preview_height
  } else {
    preview_height - 2
  }

  // Hide cursor and go home
  buf.write_string("\u001b[?25l")
  buf.write_string("\u001b[H")
  buf.write_string(ansi_reset)
  if is_right {
    // Side-by-side layout: main | preview
    self.render_split_horizontal(
      buf, main_width, preview_width, preview_lines, max_preview_lines,
    )
  } else {
    // Top-bottom layout: main on top, preview on bottom
    self.render_split_vertical(
      buf, main_height, preview_height, preview_lines, max_preview_lines,
    )
  }
  buf.to_string()
}

///|
/// Render horizontal split (main left, preview right)
fn App::render_split_horizontal(
  self : App,
  buf : StringBuilder,
  main_width : Int,
  preview_width : Int,
  preview_lines : Array[String],
  max_preview_lines : Int,
) -> Unit {
  let header_lines = @core.count_lines(self.header)
  let info_lines = if self.info == "default" { 1 } else { 0 }
  let max_items = self.height - 4 - header_lines - info_lines // prompt, separator, borders
  let (start_idx, visible_count) = self.get_visible_range(max_items)
  let items_reversed = self.is_items_reversed()
  let prompt_at_bottom = self.is_prompt_at_bottom()

  // Build main pane lines
  let main_lines : Array[String] = []

  // Top border / spacer
  let top_border = self.build_top_border_line(main_width)
  main_lines.push(top_border)
  if prompt_at_bottom {
    // Status line
    if self.info == "default" {
      main_lines.push(self.build_info_line(main_width))
    }
    // Header
    if self.header.length() > 0 {
      let hdr_lines = @core.split_lines(self.header)
      for hl in hdr_lines {
        main_lines.push(self.pad_line(hl, main_width))
      }
    }
    // Empty lines
    for j = visible_count; j < max_items; j = j + 1 {
      ignore(j)
      main_lines.push(self.pad_line("", main_width))
    }
    // Items (with scroll offset)
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        main_lines.push(self.build_item_line(start_idx + i, main_width))
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        main_lines.push(self.build_item_line(start_idx + i, main_width))
      }
    }
    // Separator
    main_lines.push(self.build_separator_line(main_width))
    // Prompt
    main_lines.push(self.build_prompt_line(main_width))
  } else {
    // Prompt at top
    main_lines.push(self.build_prompt_line(main_width))
    // Separator
    main_lines.push(self.build_separator_line(main_width))
    // Header
    if self.header.length() > 0 {
      let hdr_lines = @core.split_lines(self.header)
      for hl in hdr_lines {
        main_lines.push(self.pad_line(hl, main_width))
      }
    }
    // Items (with scroll offset)
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        main_lines.push(self.build_item_line(start_idx + i, main_width))
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        main_lines.push(self.build_item_line(start_idx + i, main_width))
      }
    }
    // Empty lines
    for j = visible_count; j < max_items; j = j + 1 {
      ignore(j)
      main_lines.push(self.pad_line("", main_width))
    }
    // Status
    if self.info == "default" {
      main_lines.push(self.build_info_line(main_width))
    }
  }

  // Bottom border
  let bottom_border = self.build_bottom_border_line(main_width)
  main_lines.push(bottom_border)

  // Build preview pane lines
  let pv_lines : Array[String] = []
  // Preview top border
  pv_lines.push(self.build_preview_top_border(preview_width))
  // Preview content
  for i = 0; i < max_preview_lines; i = i + 1 {
    if i < preview_lines.length() {
      pv_lines.push(
        self.build_preview_content_line(preview_lines[i], preview_width),
      )
    } else {
      pv_lines.push(self.build_preview_content_line("", preview_width))
    }
  }
  // Preview bottom border
  pv_lines.push(self.build_preview_bottom_border(preview_width))

  // Combine and output
  let total_lines = if main_lines.length() > pv_lines.length() {
    main_lines.length()
  } else {
    pv_lines.length()
  }
  for i = 0; i < total_lines; i = i + 1 {
    let main_part = if i < main_lines.length() {
      main_lines[i]
    } else {
      self.pad_line("", main_width)
    }
    let pv_part = if i < pv_lines.length() {
      pv_lines[i]
    } else {
      self.build_preview_content_line("", preview_width)
    }
    buf.write_string(main_part)
    buf.write_string(pv_part)
    buf.write_string("\u001b[K\r\n")
  }

  // Position cursor
  // For prompt at top: cursor_row = 1 (same as regular render)
  // For prompt at bottom: prompt is at main_lines[length-2]
  //   main_lines structure: [top_border, ..., separator, prompt, bottom_border]
  //   Array index (length-2) maps to terminal row (length-2) due to 0-indexed array vs 1-indexed rows
  let cursor_row = if prompt_at_bottom { main_lines.length() - 2 } else { 1 }
  let cursor_col = string_width(self.prompt) + 1 + self.query.length()
  buf.write_string("\u001b[")
  buf.write_string(cursor_row.to_string())
  buf.write_string(";")
  buf.write_string(cursor_col.to_string())
  buf.write_string("H")
  buf.write_string("\u001b[?25h")
}

///|
/// Render vertical split (main top, preview bottom)
fn App::render_split_vertical(
  self : App,
  buf : StringBuilder,
  main_height : Int,
  _preview_height : Int,
  preview_lines : Array[String],
  max_preview_lines : Int,
) -> Unit {
  let full_width = self.width - 1
  let header_lines = @core.count_lines(self.header)
  let info_lines = if self.info == "default" { 1 } else { 0 }
  let max_items = main_height - 4 - header_lines - info_lines
  let (start_idx, visible_count) = self.get_visible_range(max_items)
  let items_reversed = self.is_items_reversed()
  let prompt_at_bottom = self.is_prompt_at_bottom()

  // Main pane (same as non-preview but with reduced height)
  // Top border
  buf.write_string(self.build_top_border_line(full_width))
  buf.write_string("\u001b[K\r\n")
  if prompt_at_bottom {
    if self.info == "default" {
      buf.write_string(self.build_info_line(full_width))
      buf.write_string("\u001b[K\r\n")
    }
    if self.header.length() > 0 {
      let hdr_lines = @core.split_lines(self.header)
      for hl in hdr_lines {
        buf.write_string(self.pad_line(hl, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    }
    for j = visible_count; j < max_items; j = j + 1 {
      ignore(j)
      buf.write_string("\u001b[K\r\n")
    }
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        buf.write_string(self.build_item_line(start_idx + i, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        buf.write_string(self.build_item_line(start_idx + i, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    }
    buf.write_string(self.build_separator_line(full_width))
    buf.write_string("\u001b[K\r\n")
    buf.write_string(self.build_prompt_line(full_width))
    buf.write_string("\u001b[K\r\n")
  } else {
    buf.write_string(self.build_prompt_line(full_width))
    buf.write_string("\u001b[K\r\n")
    buf.write_string(self.build_separator_line(full_width))
    buf.write_string("\u001b[K\r\n")
    if self.header.length() > 0 {
      let hdr_lines = @core.split_lines(self.header)
      for hl in hdr_lines {
        buf.write_string(self.pad_line(hl, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    }
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        buf.write_string(self.build_item_line(start_idx + i, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        buf.write_string(self.build_item_line(start_idx + i, full_width))
        buf.write_string("\u001b[K\r\n")
      }
    }
    for j = visible_count; j < max_items; j = j + 1 {
      ignore(j)
      buf.write_string("\u001b[K\r\n")
    }
    if self.info == "default" {
      buf.write_string(self.build_info_line(full_width))
      buf.write_string("\u001b[K\r\n")
    }
  }

  // Preview pane (bottom)
  buf.write_string(self.build_preview_top_border(full_width))
  buf.write_string("\u001b[K\r\n")
  for i = 0; i < max_preview_lines; i = i + 1 {
    if i < preview_lines.length() {
      buf.write_string(
        self.build_preview_content_line(preview_lines[i], full_width),
      )
    } else {
      buf.write_string(self.build_preview_content_line("", full_width))
    }
    buf.write_string("\u001b[K\r\n")
  }
  buf.write_string(self.build_preview_bottom_border(full_width))
  buf.write_string("\u001b[K")

  // Position cursor
  // For prompt at top: cursor_row = 1
  // For prompt at bottom: prompt is at main_height - 1 (before bottom border of main pane)
  let cursor_row = if prompt_at_bottom { main_height - 1 } else { 1 }
  let cursor_col = string_width(self.prompt) + 1 + self.query.length()
  buf.write_string("\u001b[")
  buf.write_string(cursor_row.to_string())
  buf.write_string(";")
  buf.write_string(cursor_col.to_string())
  buf.write_string("H")
  buf.write_string("\u001b[?25h")
}

///|
/// Build top border line for main pane
fn App::build_top_border_line(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  if self.border == "none" {
    // Just spaces
    for i = 0; i < width; i = i + 1 {
      ignore(i)
      buf.write_char(' ')
    }
  } else {
    let (tl, tr, _, _, h_char, _) = get_border_chars(self.border)
    buf.write_string(self.colors.border)
    if self.border == "horizontal" {
      for i = 0; i < width; i = i + 1 {
        ignore(i)
        buf.write_string(h_char)
      }
    } else {
      buf.write_string(tl)
      for i = 0; i < width - 2; i = i + 1 {
        ignore(i)
        buf.write_string(h_char)
      }
      buf.write_string(tr)
    }
    buf.write_string(ansi_reset)
  }
  buf.to_string()
}

///|
/// Build bottom border line for main pane
fn App::build_bottom_border_line(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  if self.border == "none" {
    for i = 0; i < width; i = i + 1 {
      ignore(i)
      buf.write_char(' ')
    }
  } else {
    let (_, _, bl, br, h_char, _) = get_border_chars(self.border)
    buf.write_string(self.colors.border)
    if self.border == "horizontal" {
      for i = 0; i < width; i = i + 1 {
        ignore(i)
        buf.write_string(h_char)
      }
    } else {
      buf.write_string(bl)
      for i = 0; i < width - 2; i = i + 1 {
        ignore(i)
        buf.write_string(h_char)
      }
      buf.write_string(br)
    }
    buf.write_string(ansi_reset)
  }
  buf.to_string()
}

///|
/// Build prompt line (without newline)
fn App::build_prompt_line(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.prompt)
  buf.write_string(self.prompt)
  buf.write_string(ansi_reset)
  buf.write_string(self.colors.fg)
  buf.write_string(self.query)
  buf.write_string(ansi_reset)
  buf.write_string(ansi_dim)
  buf.write_string("_")
  buf.write_string(ansi_reset)
  if self.info == "inline" {
    buf.write_string(" ")
    buf.write_string(self.colors.info)
    if self.marked.length() > 0 {
      buf.write_string(self.marked.length().to_string())
      buf.write_string("/")
    }
    buf.write_string(self.filtered.length().to_string())
    buf.write_string("/")
    buf.write_string(self.items.length().to_string())
    buf.write_string(ansi_reset)
  }
  // Pad to width
  let content_len = string_width(self.prompt) +
    self.query.length() +
    1 +
    (if self.info == "inline" {
      self.filtered.length().to_string().length() +
      self.items.length().to_string().length() +
      3
    } else {
      0
    })
  for i = content_len; i < width; i = i + 1 {
    ignore(i)
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Build separator line
fn App::build_separator_line(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  let (_, _, _, _, h_char, _) = get_border_chars(self.border)
  let sep_char = if h_char.length() > 0 { h_char } else { "─" }
  buf.write_string(self.colors.border)
  for i = 0; i < width; i = i + 1 {
    ignore(i)
    buf.write_string(sep_char)
  }
  buf.write_string(ansi_reset)
  buf.to_string()
}

///|
/// Build info line
fn App::build_info_line(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.info)
  if self.marked.length() > 0 {
    buf.write_string(self.marked.length().to_string())
    buf.write_string("/")
  }
  buf.write_string(self.filtered.length().to_string())
  buf.write_string("/")
  buf.write_string(self.items.length().to_string())
  buf.write_string(ansi_reset)
  // Pad
  let content_len = self.filtered.length().to_string().length() +
    self.items.length().to_string().length() +
    1
  for i = content_len; i < width; i = i + 1 {
    ignore(i)
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Build item line (without newline)
fn App::build_item_line(self : App, idx : Int, width : Int) -> String {
  let buf = StringBuilder::new()
  let result = self.filtered[idx]
  let is_cursor = idx == self.selected_idx
  let is_marked = self.is_marked(result.item.original_index)

  // Marker
  if is_marked {
    buf.write_string(self.colors.marker)
    buf.write_string(self.marker)
    buf.write_string(ansi_reset)
  } else {
    for k = 0; k < string_width(self.marker); k = k + 1 {
      ignore(k)
      buf.write_char(' ')
    }
  }

  // Pointer
  if is_cursor {
    buf.write_string(ansi_reverse)
    buf.write_string(self.colors.pointer)
    buf.write_string(self.pointer)
  } else {
    for k = 0; k < string_width(self.pointer); k = k + 1 {
      ignore(k)
      buf.write_char(' ')
    }
  }

  // Text
  let display_text = self.get_display_text(result.item.text)
  let prefix_len = string_width(self.marker) + string_width(self.pointer)
  let max_text_len = width - prefix_len
  let truncated = truncate_to_width(display_text, max_text_len)
  if is_cursor {
    buf.write_string(truncated)
    buf.write_string(ansi_reset)
  } else if self.with_nth.length() > 0 {
    buf.write_string(truncated)
  } else {
    buf.write_string(
      highlight_text(truncated, result.match_positions, self.colors.hl),
    )
  }

  // Pad to width
  let text_len = prefix_len + truncated.length()
  for i = text_len; i < width; i = i + 1 {
    ignore(i)
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Pad a line to specified width
fn App::pad_line(self : App, s : String, width : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.header)
  buf.write_string(s)
  buf.write_string(ansi_reset)
  let len = s.length()
  for i = len; i < width; i = i + 1 {
    ignore(i)
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Build preview pane top border
fn App::build_preview_top_border(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.border)
  buf.write_string("┌")
  for i = 0; i < width - 2; i = i + 1 {
    ignore(i)
    buf.write_string("─")
  }
  buf.write_string("┐")
  buf.write_string(ansi_reset)
  buf.to_string()
}

///|
/// Build preview pane bottom border
fn App::build_preview_bottom_border(self : App, width : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.border)
  buf.write_string("└")
  for i = 0; i < width - 2; i = i + 1 {
    ignore(i)
    buf.write_string("─")
  }
  buf.write_string("┘")
  buf.write_string(ansi_reset)
  buf.to_string()
}

///|
/// Build preview content line with borders (ANSI-aware)
fn App::build_preview_content_line(
  self : App,
  content : String,
  width : Int,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string(self.colors.border)
  buf.write_string("│")
  buf.write_string(ansi_reset)
  let content_width = width - 2
  let truncated = truncate_to_visible_width(content, content_width)
  buf.write_string(truncated)
  buf.write_string(ansi_reset) // Reset after ANSI content
  let vis_len = visible_width(truncated)
  for i = vis_len; i < content_width; i = i + 1 {
    ignore(i)
    buf.write_char(' ')
  }
  buf.write_string(self.colors.border)
  buf.write_string("│")
  buf.write_string(ansi_reset)
  buf.to_string()
}

///|
/// Render the UI
pub fn App::render(self : App) -> String {
  // If preview is enabled, use split pane rendering
  if self.has_preview() {
    return self.render_with_preview()
  }
  let buf = StringBuilder::new()
  // Reserve lines for prompt, status, and header if present
  let header_lines = @core.count_lines(self.header)
  // Adjust for info line (not needed when inline or hidden)
  let info_lines = if self.info == "default" { 1 } else { 0 }
  // Adjust for border lines (top line is always reserved now for border or spacer)
  let top_line = 1 // Always have top border or spacer line
  let bottom_line = if self.border != "none" { 1 } else { 0 }
  let max_visible = self.height -
    2 -
    header_lines -
    info_lines -
    top_line -
    bottom_line

  // Hide cursor and clear screen
  buf.write_string("\u001b[?25l") // Hide cursor
  buf.write_string("\u001b[H") // Move to home first
  buf.write_string(ansi_reset) // Reset all attributes to ensure clean state
  let (start_idx, visible_count) = self.get_visible_range(max_visible)
  let prompt_at_bottom = self.is_prompt_at_bottom()
  let items_reversed = self.is_items_reversed()
  if prompt_at_bottom {
    // Reverse layout: status at top, items bottom-to-top, prompt at bottom
    // Top border (or empty line for terminal compatibility)
    if self.border == "none" {
      buf.write_string("\u001b[K") // Clear first line
      buf.write_string("\r\n")
    } else {
      self.render_top_border(buf)
    }

    // Status line (if default - not inline or hidden)
    if self.info == "default" {
      self.render_info(buf)
      buf.write_string("\r\n")
    }

    // Header (if present)
    self.render_header(buf)

    // Fill empty lines first (clear each line to remove old content)
    for j = visible_count; j < max_visible; j = j + 1 {
      ignore(j)
      buf.write_string("\u001b[K") // Clear to end of line
      buf.write_string("\r\n")
    }

    // Render items (with scroll offset)
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        self.render_item(buf, start_idx + i)
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        self.render_item(buf, start_idx + i)
      }
    }

    // Separator
    self.render_separator(buf)
    buf.write_string("\r\n")

    // Render prompt line at bottom
    self.render_prompt_line(buf)
    buf.write_string("\r\n")

    // Bottom border
    self.render_bottom_border(buf)

    // Show cursor at query position (bottom line in reverse mode)
    let border_offset = if self.border != "none" { 1 } else { 0 }
    let cursor_row = self.height - border_offset - 1
    let cursor_col = string_width(self.prompt) + 1 + self.query.length()
    if self.row_offset > 0 {
      // Inline mode: use relative cursor movement
      // After rendering, cursor is at bottom. Move up to prompt line.
      let lines_up = self.height - cursor_row
      if lines_up > 0 {
        buf.write_string("\u001b[")
        buf.write_string(lines_up.to_string())
        buf.write_string("A") // Move up
      }
      buf.write_string("\u001b[")
      buf.write_string(cursor_col.to_string())
      buf.write_string("G") // Move to column
    } else {
      // Full screen mode: use absolute positioning
      buf.write_string("\u001b[")
      buf.write_string(cursor_row.to_string())
      buf.write_string(";")
      buf.write_string(cursor_col.to_string())
      buf.write_string("H")
    }
    buf.write_string("\u001b[?25h") // Show cursor
  } else {
    // Default layout: prompt at top, items top-to-bottom, status at bottom
    // Top border (or empty line to push prompt to row 2 for terminal compatibility)
    if self.border == "none" {
      buf.write_string("\u001b[K") // Clear first line
      buf.write_string("\r\n")
    } else {
      self.render_top_border(buf)
    }

    // Render prompt line
    self.render_prompt_line(buf)
    buf.write_string("\r\n")

    // Separator
    self.render_separator(buf)
    buf.write_string("\r\n")

    // Header (if present)
    self.render_header(buf)

    // Render items (with scroll offset)
    if items_reversed {
      for i = visible_count - 1; i >= 0; i = i - 1 {
        self.render_item(buf, start_idx + i)
      }
    } else {
      for i = 0; i < visible_count; i = i + 1 {
        self.render_item(buf, start_idx + i)
      }
    }

    // Fill remaining lines (clear each line to remove old content)
    for j = visible_count; j < max_visible; j = j + 1 {
      ignore(j)
      buf.write_string("\u001b[K") // Clear to end of line
      buf.write_string("\r\n")
    }

    // Status line (if default - not inline or hidden)
    if self.info == "default" {
      self.render_info(buf)
      buf.write_string("\r\n")
    }

    // Bottom border
    self.render_bottom_border(buf)

    // Show cursor at query position
    let cursor_row = 1
    let cursor_col = string_width(self.prompt) + 1 + self.query.length()
    if self.row_offset > 0 {
      // Inline mode: use relative cursor movement
      // After rendering, cursor is at bottom. Move up to prompt line (row 1 means top).
      let lines_up = self.height - cursor_row
      if lines_up > 0 {
        buf.write_string("\u001b[")
        buf.write_string(lines_up.to_string())
        buf.write_string("A") // Move up
      }
      buf.write_string("\u001b[")
      buf.write_string(cursor_col.to_string())
      buf.write_string("G") // Move to column
    } else {
      // Full screen mode: use absolute positioning
      buf.write_string("\u001b[")
      buf.write_string(cursor_row.to_string())
      buf.write_string(";")
      buf.write_string(cursor_col.to_string())
      buf.write_string("H")
    }
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
/// Calculate the start index for visible items to ensure selected item is visible
/// Returns (start_idx, visible_count) where items from start_idx to start_idx+visible_count-1 should be rendered
fn App::get_visible_range(self : App, max_visible : Int) -> (Int, Int) {
  let total = self.filtered.length()
  if total <= max_visible {
    // All items fit, no scrolling needed
    return (0, total)
  }
  // Need to scroll - ensure selected_idx is visible
  let start_idx = if self.selected_idx < max_visible {
    // Selected is in first page
    0
  } else if self.selected_idx >= total - max_visible {
    // Selected is in last page
    total - max_visible
  } else {
    // Selected is in middle - keep it centered (or at least visible)
    self.selected_idx - max_visible / 2
  }
  (start_idx, max_visible)
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

///|
/// Check if preview is enabled
pub fn App::has_preview(self : App) -> Bool {
  self.preview_command.length() > 0
}

///|
/// Get preview command template
pub fn App::get_preview_command(self : App) -> String {
  self.preview_command
}

///|
/// Get preview window spec
pub fn App::get_preview_window(self : App) -> String {
  self.preview_window
}

///|
/// Get current selected item text (for preview)
pub fn App::get_current_item(self : App) -> String? {
  if self.filtered.length() > 0 && self.selected_idx < self.filtered.length() {
    Some(self.filtered[self.selected_idx].item.text)
  } else {
    None
  }
}

///|
/// Get current selected item index (original_index, 1-indexed for preview)
pub fn App::get_current_line_num(self : App) -> Int {
  if self.filtered.length() > 0 && self.selected_idx < self.filtered.length() {
    self.filtered[self.selected_idx].item.original_index + 1
  } else {
    0
  }
}

///|
/// Get all marked item texts
pub fn App::get_marked_items(self : App) -> Array[String] {
  let result : Array[String] = []
  for idx in self.marked {
    for item in self.items {
      if item.original_index == idx {
        result.push(item.text)
        break
      }
    }
  }
  result
}

///|
/// Get marked item indices (0-indexed)
pub fn App::get_marked_indices(self : App) -> Array[Int] {
  self.marked.copy()
}

///|
/// Check if preview needs update (selection changed)
pub fn App::preview_needs_update(self : App) -> Bool {
  self.preview_item_idx != self.selected_idx
}

///|
/// Set preview cache content
pub fn App::set_preview_cache(self : App, content : String) -> Unit {
  self.preview_cache = content
  self.preview_item_idx = self.selected_idx
}

///|
/// Get preview cache content
pub fn App::get_preview_cache(self : App) -> String {
  self.preview_cache
}
