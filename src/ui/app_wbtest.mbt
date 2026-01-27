// =============================================================================
// App Whitebox Tests
// =============================================================================

///|
test "app: new with default empty query" {
  let items = [@core.Item::new("foo.txt", 0), @core.Item::new("bar.txt", 1)]
  let app = App::new(items, 80, 24)
  assert_eq(app.query, "")
  assert_eq(app.filtered.length(), 2)
  assert_eq(app.selected_idx, 0)
  assert_eq(app.is_running(), true)
}

///|
test "app: new with initial query" {
  let items = [
    @core.Item::new("foo.txt", 0),
    @core.Item::new("bar.txt", 1),
    @core.Item::new("foobar.txt", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="foo")
  assert_eq(app.query, "foo")
  assert_eq(app.filtered.length(), 2)
  assert_eq(app.selected_idx, 0)
}

///|
test "app: initial query filters results" {
  let items = [
    @core.Item::new("apple.txt", 0),
    @core.Item::new("banana.txt", 1),
    @core.Item::new("cherry.txt", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="ban")
  assert_eq(app.filtered.length(), 1)
  assert_eq(app.filtered[0].item.text, "banana.txt")
}

///|
test "app: initial query no match" {
  let items = [@core.Item::new("foo.txt", 0), @core.Item::new("bar.txt", 1)]
  let app = App::new(items, 80, 24, initial_query="xyz")
  assert_eq(app.filtered.length(), 0)
  assert_eq(app.selected_idx, 0)
}

///|
test "app: handle char appends to query" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24)
  app.handle_char('a')
  assert_eq(app.query, "a")
  app.handle_char('b')
  assert_eq(app.query, "ab")
}

///|
test "app: handle backspace removes char" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, initial_query="abc")
  app.handle_backspace()
  assert_eq(app.query, "ab")
  app.handle_backspace()
  assert_eq(app.query, "a")
}

///|
test "app: handle backspace on empty query" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24)
  app.handle_backspace()
  assert_eq(app.query, "")
}

///|
test "app: clear input resets query" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, initial_query="hello")
  app.clear_input()
  assert_eq(app.query, "")
}

///|
test "app: select up and down" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  assert_eq(app.selected_idx, 0)
  app.select_down()
  assert_eq(app.selected_idx, 1)
  app.select_down()
  assert_eq(app.selected_idx, 2)
  app.select_down()
  assert_eq(app.selected_idx, 2)
  app.select_up()
  assert_eq(app.selected_idx, 1)
  app.select_up()
  assert_eq(app.selected_idx, 0)
  app.select_up()
  assert_eq(app.selected_idx, 0)
}

///|
test "app: confirm selection sets result" {
  let items = [
    @core.Item::new("first.txt", 0),
    @core.Item::new("second.txt", 1),
  ]
  let app = App::new(items, 80, 24)
  app.select_down()
  app.confirm_selection()
  assert_eq(app.is_running(), false)
  assert_eq(app.get_result(), Some("second.txt"))
}

///|
test "app: cancel sets no result" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24)
  app.cancel()
  assert_eq(app.is_running(), false)
  assert_eq(app.get_result(), None)
}

///|
test "app: confirm with empty filtered" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, initial_query="xyz")
  app.confirm_selection()
  assert_eq(app.is_running(), false)
  assert_eq(app.get_result(), None)
}

///|
test "app: render returns non-empty string" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24)
  let output = app.render()
  assert_true(output.length() > 0)
}

///|
test "app: render contains query" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, initial_query="hello")
  let output = app.render()
  assert_true(output.contains("hello"))
}

///|
test "app: update filter with empty query shows all" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="a")
  assert_eq(app.filtered.length(), 1)
  app.query = ""
  app.update_filter()
  assert_eq(app.filtered.length(), 3)
}

///|
test "app: selected_idx resets when filter changes" {
  let items = [
    @core.Item::new("aaa.txt", 0),
    @core.Item::new("bbb.txt", 1),
    @core.Item::new("ccc.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  app.selected_idx = 2
  app.handle_char('a') // Now only "aaa.txt" matches
  assert_eq(app.selected_idx, 0)
}

// =============================================================================
// Multi-select Tests
// =============================================================================

///|
test "multiselect: initial marked array is empty" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  assert_eq(app.marked.length(), 0)
}

///|
test "multiselect: toggle_mark adds item to marked" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  app.toggle_mark()
  assert_eq(app.marked.length(), 1)
  assert_eq(app.marked[0], 0) // original_index of first item
}

///|
test "multiselect: toggle_mark moves selection down" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  assert_eq(app.selected_idx, 0)
  app.toggle_mark()
  assert_eq(app.selected_idx, 1)
}

///|
test "multiselect: toggle_mark removes item if already marked" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  app.toggle_mark() // Add
  assert_eq(app.marked.length(), 1)
  app.selected_idx = 0 // Go back to first item
  app.toggle_mark() // Remove
  assert_eq(app.marked.length(), 0)
}

///|
test "multiselect: toggle_mark on empty filtered does nothing" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, initial_query="xyz")
  assert_eq(app.filtered.length(), 0)
  app.toggle_mark()
  assert_eq(app.marked.length(), 0)
}

///|
test "multiselect: is_marked returns true for marked item" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  app.toggle_mark()
  assert_eq(app.is_marked(0), true)
  assert_eq(app.is_marked(1), false)
}

///|
test "multiselect: mark multiple items" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  app.toggle_mark() // Mark a.txt, moves to b.txt
  app.toggle_mark() // Mark b.txt, moves to c.txt
  assert_eq(app.marked.length(), 2)
  assert_eq(app.is_marked(0), true)
  assert_eq(app.is_marked(1), true)
  assert_eq(app.is_marked(2), false)
}

///|
test "multiselect: confirm returns all marked items" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  app.toggle_mark() // Mark a.txt
  app.toggle_mark() // Mark b.txt
  app.confirm_selection()
  let result = app.get_result()
  match result {
    Some(text) => {
      assert_true(text.contains("a.txt"))
      assert_true(text.contains("b.txt"))
      assert_true(not(text.contains("c.txt")))
    }
    None => panic()
  }
}

///|
test "multiselect: confirm with no marks returns current item" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  app.select_down() // Select b.txt
  app.confirm_selection()
  assert_eq(app.get_result(), Some("b.txt"))
}

///|
test "multiselect: marked items separated by newline" {
  let items = [
    @core.Item::new("first.txt", 0),
    @core.Item::new("second.txt", 1),
  ]
  let app = App::new(items, 80, 24)
  app.toggle_mark()
  app.toggle_mark()
  app.confirm_selection()
  let result = app.get_result()
  match result {
    Some(text) => assert_true(text.contains("\n"))
    None => panic()
  }
}

///|
test "multiselect: render shows marker for marked items" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  app.toggle_mark() // Mark first item
  let output = app.render()
  assert_true(output.contains("*"))
}

///|
test "multiselect: status line shows marked count" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24)
  app.toggle_mark()
  app.toggle_mark()
  let output = app.render()
  // Status line should show "2/3/3" (2 marked, 3 filtered, 3 total)
  assert_true(output.contains("2/"))
}

// =============================================================================
// Display Options Tests
// =============================================================================

///|
test "options: default values" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.reverse, false)
  assert_eq(app.prompt, "> ")
  assert_eq(app.pointer, "> ")
  assert_eq(app.marker, "*")
}

///|
test "options: custom prompt" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, prompt=">>> ")
  assert_eq(app.prompt, ">>> ")
  let output = app.render()
  assert_true(output.contains(">>> "))
}

///|
test "options: custom pointer" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, pointer="▶ ")
  assert_eq(app.pointer, "▶ ")
  let output = app.render()
  assert_true(output.contains("▶ "))
}

///|
test "options: custom marker" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24, marker="✓")
  assert_eq(app.marker, "✓")
  app.toggle_mark()
  let output = app.render()
  assert_true(output.contains("✓"))
}

///|
test "options: reverse mode enabled" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, reverse=true)
  assert_eq(app.reverse, true)
  // In reverse mode, render should still return a valid string
  let output = app.render()
  assert_true(output.length() > 0)
}

///|
test "options: combined options" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(
    items,
    80,
    24,
    reverse=true,
    prompt="? ",
    pointer="→ ",
    marker="●",
  )
  assert_eq(app.reverse, true)
  assert_eq(app.prompt, "? ")
  assert_eq(app.pointer, "→ ")
  assert_eq(app.marker, "●")
}
