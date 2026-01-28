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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
  assert_eq(app.selected_idx, 0)
  app.toggle_mark()
  assert_eq(app.selected_idx, 1)
}

///|
test "multiselect: toggle_mark removes item if already marked" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24, multi=true)
  app.toggle_mark() // Add
  assert_eq(app.marked.length(), 1)
  app.selected_idx = 0 // Go back to first item
  app.toggle_mark() // Remove
  assert_eq(app.marked.length(), 0)
}

///|
test "multiselect: toggle_mark on empty filtered does nothing" {
  let items = [@core.Item::new("test.txt", 0)]
  let app = App::new(items, 80, 24, multi=true, initial_query="xyz")
  assert_eq(app.filtered.length(), 0)
  app.toggle_mark()
  assert_eq(app.marked.length(), 0)
}

///|
test "multiselect: is_marked returns true for marked item" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true)
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
  let app = App::new(items, 80, 24, multi=true, marker="✓")
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

// =============================================================================
// Cycle Mode Tests (TDD - tests written first)
// =============================================================================

///|
test "cycle: select_down wraps to top" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24, cycle=true)
  app.selected_idx = 2 // At bottom
  app.select_down() // Should wrap to top
  assert_eq(app.selected_idx, 0)
}

///|
test "cycle: select_up wraps to bottom" {
  let items = [
    @core.Item::new("a.txt", 0),
    @core.Item::new("b.txt", 1),
    @core.Item::new("c.txt", 2),
  ]
  let app = App::new(items, 80, 24, cycle=true)
  app.selected_idx = 0 // At top
  app.select_up() // Should wrap to bottom
  assert_eq(app.selected_idx, 2)
}

///|
test "cycle: disabled by default" {
  let items = [@core.Item::new("a.txt", 0), @core.Item::new("b.txt", 1)]
  let app = App::new(items, 80, 24)
  assert_eq(app.cycle, false)
  app.selected_idx = 1
  app.select_down() // Should stay at bottom
  assert_eq(app.selected_idx, 1)
}

// =============================================================================
// No-Sort Mode Tests (TDD - tests written first)
// =============================================================================

///|
test "no_sort: keeps original order" {
  let items = [
    @core.Item::new("zebra.txt", 0),
    @core.Item::new("alpha.txt", 1),
    @core.Item::new("beta.txt", 2),
  ]
  let app = App::new(items, 80, 24, no_sort=true, initial_query="a")
  // With no_sort, filtered items should keep original order
  // "zebra" has 'a', "alpha" has 'a', "beta" has 'a'
  // Without sorting, order should be: zebra, alpha, beta
  assert_eq(app.filtered[0].item.text, "zebra.txt")
  assert_eq(app.filtered[1].item.text, "alpha.txt")
  assert_eq(app.filtered[2].item.text, "beta.txt")
}

///|
test "no_sort: disabled by default sorts by score" {
  let items = [@core.Item::new("xxxabc.txt", 0), @core.Item::new("abc.txt", 1)]
  let app = App::new(items, 80, 24, initial_query="abc")
  assert_eq(app.no_sort, false)
  // With sorting, "abc.txt" should be first (better match)
  assert_eq(app.filtered[0].item.text, "abc.txt")
}

// =============================================================================
// Nth Field Matching Tests (TDD - tests written first)
// =============================================================================

///|
test "nth: match first field only" {
  let items = [
    @core.Item::new("foo:bar:baz", 0),
    @core.Item::new("bar:foo:baz", 1),
    @core.Item::new("baz:bar:foo", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="foo", nth="1", delimiter=":")
  // Only first item should match (foo in first field)
  assert_eq(app.filtered.length(), 1)
  assert_eq(app.filtered[0].item.text, "foo:bar:baz")
}

///|
test "nth: match multiple fields" {
  let items = [
    @core.Item::new("a:b:c", 0),
    @core.Item::new("x:a:y", 1),
    @core.Item::new("x:y:a", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="a", nth="1,2", delimiter=":")
  // First two should match (a in field 1 or 2)
  assert_eq(app.filtered.length(), 2)
}

///|
test "nth: negative index from end" {
  let items = [@core.Item::new("a:b:foo", 0), @core.Item::new("foo:b:c", 1)]
  let app = App::new(
    items,
    80,
    24,
    initial_query="foo",
    nth="-1",
    delimiter=":",
  )
  // Only first item should match (foo in last field)
  assert_eq(app.filtered.length(), 1)
  assert_eq(app.filtered[0].item.text, "a:b:foo")
}

///|
test "nth: empty nth matches all fields (default)" {
  let items = [@core.Item::new("foo:bar", 0), @core.Item::new("bar:foo", 1)]
  let app = App::new(items, 80, 24, initial_query="foo", nth="", delimiter=":")
  // Both should match
  assert_eq(app.filtered.length(), 2)
}

///|
test "delimiter: default is empty (no field splitting)" {
  let items = [@core.Item::new("foo:bar", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.delimiter, "")
}

///|
test "delimiter: custom delimiter" {
  let items = [@core.Item::new("foo|bar|baz", 0)]
  let app = App::new(items, 80, 24, delimiter="|")
  assert_eq(app.delimiter, "|")
}

// =============================================================================
// Exact Match Tests (TDD)
// =============================================================================

///|
test "exact: matches substring exactly" {
  let items = [
    @core.Item::new("foobar", 0),
    @core.Item::new("foXobar", 1),
    @core.Item::new("foo", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="foo", exact=true)
  // Exact mode: only "foobar" and "foo" contain "foo" as substring
  // "foXobar" should NOT match because "foo" is not a contiguous substring
  assert_eq(app.filtered.length(), 2)
}

///|
test "exact: no fuzzy matching" {
  let items = [@core.Item::new("abc", 0), @core.Item::new("aXbXc", 1)]
  let app = App::new(items, 80, 24, initial_query="abc", exact=true)
  // Only "abc" should match, not "aXbXc"
  assert_eq(app.filtered.length(), 1)
  assert_eq(app.filtered[0].item.text, "abc")
}

///|
test "exact: default is fuzzy" {
  let items = [@core.Item::new("abc", 0), @core.Item::new("aXbXc", 1)]
  let app = App::new(items, 80, 24, initial_query="abc", exact=false)
  // Both should match with fuzzy
  assert_eq(app.filtered.length(), 2)
}

// =============================================================================
// Ignore Case Tests (TDD)
// =============================================================================

///|
test "ignore_case: forces case insensitive" {
  let items = [
    @core.Item::new("ABC", 0),
    @core.Item::new("abc", 1),
    @core.Item::new("Abc", 2),
  ]
  let app = App::new(items, 80, 24, initial_query="ABC", ignore_case=true)
  // All should match with ignore_case
  assert_eq(app.filtered.length(), 3)
}

///|
test "ignore_case: default uses smart case" {
  let items = [@core.Item::new("ABC", 0), @core.Item::new("abc", 1)]
  let app = App::new(items, 80, 24, initial_query="ABC", ignore_case=false)
  // Smart case: uppercase query = case sensitive, only "ABC" matches
  assert_eq(app.filtered.length(), 1)
  assert_eq(app.filtered[0].item.text, "ABC")
}

// =============================================================================
// Header Tests (TDD)
// =============================================================================

///|
test "header: default is empty" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.header, "")
}

///|
test "header: custom header" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24, header="Select a file:")
  assert_eq(app.header, "Select a file:")
}

///|
test "header: render includes header" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24, header="My Header")
  let output = app.render()
  assert_true(output.contains("My Header"))
}

// =============================================================================
// with-nth Tests (TDD)
// =============================================================================

///|
test "with_nth: default is empty" {
  let items = [@core.Item::new("a b c", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.with_nth, "")
}

///|
test "with_nth: custom value" {
  let items = [@core.Item::new("a b c", 0)]
  let app = App::new(items, 80, 24, with_nth="1,3", delimiter=" ")
  assert_eq(app.with_nth, "1,3")
}

// =============================================================================
// expect Tests (TDD)
// =============================================================================

///|
test "expect: default is empty" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.expect, "")
}

///|
test "expect: custom value" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24, expect="ctrl-v,ctrl-o")
  assert_eq(app.expect, "ctrl-v,ctrl-o")
}

// =============================================================================
// ansi Tests (TDD)
// =============================================================================

///|
test "ansi: default is false" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.ansi, false)
}

///|
test "ansi: enabled" {
  let items = [@core.Item::new("\u001b[31mred\u001b[0m", 0)]
  let app = App::new(items, 80, 24, ansi=true)
  assert_eq(app.ansi, true)
}

///|
test "ansi: filters by stripped text" {
  let items = [
    @core.Item::new("\u001b[31mred\u001b[0m", 0),
    @core.Item::new("\u001b[32mgreen\u001b[0m", 1),
    @core.Item::new("\u001b[34mblue\u001b[0m", 2),
  ]
  let app = App::new(items, 80, 24, ansi=true, initial_query="gre")
  // Should match "green" even though it has ANSI codes
  assert_eq(app.filtered.length(), 1)
  // Result should preserve original text with ANSI codes
  assert_true(app.filtered[0].item.text.contains("\u001b[32m"))
}

///|
test "ansi: preserves original text in result" {
  let items = [@core.Item::new("\u001b[1;33myellow\u001b[0m", 0)]
  let app = App::new(items, 80, 24, ansi=true, initial_query="yell")
  assert_eq(app.filtered.length(), 1)
  // Original text with ANSI should be preserved
  assert_eq(app.filtered[0].item.text, "\u001b[1;33myellow\u001b[0m")
}

///|
test "ansi: works with exact mode" {
  let items = [
    @core.Item::new("\u001b[31mabc\u001b[0m", 0),
    @core.Item::new("\u001b[32mabXc\u001b[0m", 1),
  ]
  let app = App::new(items, 80, 24, ansi=true, exact=true, initial_query="abc")
  // Only "abc" should match in exact mode
  assert_eq(app.filtered.length(), 1)
  assert_true(app.filtered[0].item.text.contains("abc"))
}

// =============================================================================
// History Tests (TDD)
// =============================================================================

///|
test "history: default is empty" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24)
  assert_eq(app.has_history(), false)
  assert_eq(app.history_idx, -1)
}

///|
test "history: custom history" {
  let items = [@core.Item::new("test", 0)]
  let history = ["query1", "query2", "query3"]
  let app = App::new(items, 80, 24, history~)
  assert_eq(app.has_history(), true)
  assert_eq(app.history.length(), 3)
}

///|
test "history: navigate prev" {
  let items = [@core.Item::new("test", 0)]
  let history = ["old1", "old2", "recent"]
  let app = App::new(items, 80, 24, history~, initial_query="current")

  // Navigate to most recent history entry
  app.history_prev()
  assert_eq(app.history_idx, 0)
  assert_eq(app.query, "recent")

  // Navigate to older entry
  app.history_prev()
  assert_eq(app.history_idx, 1)
  assert_eq(app.query, "old2")
}

///|
test "history: navigate next returns to current" {
  let items = [@core.Item::new("test", 0)]
  let history = ["old", "recent"]
  let app = App::new(items, 80, 24, history~, initial_query="current")

  // Go back in history
  app.history_prev()
  assert_eq(app.query, "recent")

  // Return to current query
  app.history_next()
  assert_eq(app.history_idx, -1)
  assert_eq(app.query, "current")
}

///|
test "history: reset on char input" {
  let items = [@core.Item::new("test", 0)]
  let history = ["old"]
  let app = App::new(items, 80, 24, history~)

  // Navigate to history
  app.history_prev()
  assert_eq(app.history_idx, 0)

  // Type a character should reset history
  app.handle_char('x')
  assert_eq(app.history_idx, -1)
}

///|
test "history: saved_query preserves original" {
  let items = [@core.Item::new("test", 0)]
  let history = ["old"]
  let app = App::new(items, 80, 24, history~, initial_query="my query")

  // Navigate to history - should save current query
  app.history_prev()
  assert_eq(app.saved_query, "my query")

  // Navigate back - should restore
  app.history_next()
  assert_eq(app.query, "my query")
}

// =============================================================================
// Page Up/Down Tests
// =============================================================================

///|
test "page_up: moves selection up by page size" {
  // Create 20 items
  let items : Array[@core.Item] = []
  for i = 0; i < 20; i = i + 1 {
    items.push(@core.Item::new("item" + i.to_string(), i))
  }
  let app = App::new(items, 80, 10) // Small height for testing
  app.selected_idx = 15
  app.select_page_up()
  assert_true(app.selected_idx < 15)
}

///|
test "page_down: moves selection down by page size" {
  let items : Array[@core.Item] = []
  for i = 0; i < 20; i = i + 1 {
    items.push(@core.Item::new("item" + i.to_string(), i))
  }
  let app = App::new(items, 80, 10)
  app.selected_idx = 0
  app.select_page_down()
  assert_true(app.selected_idx > 0)
}

///|
test "page_up: stops at top without cycle" {
  let items : Array[@core.Item] = []
  for i = 0; i < 20; i = i + 1 {
    items.push(@core.Item::new("item" + i.to_string(), i))
  }
  let app = App::new(items, 80, 10, cycle=false)
  app.selected_idx = 2
  app.select_page_up()
  assert_eq(app.selected_idx, 0)
}

///|
test "page_down: stops at bottom without cycle" {
  let items : Array[@core.Item] = []
  for i = 0; i < 20; i = i + 1 {
    items.push(@core.Item::new("item" + i.to_string(), i))
  }
  let app = App::new(items, 80, 10, cycle=false)
  app.selected_idx = 18
  app.select_page_down()
  assert_eq(app.selected_idx, 19)
}

///|
test "page_up: wraps with cycle enabled" {
  let items : Array[@core.Item] = []
  for i = 0; i < 30; i = i + 1 {
    items.push(@core.Item::new("item" + i.to_string(), i))
  }
  let app = App::new(items, 80, 10, cycle=true) // height 10 = page_size ~5
  app.selected_idx = 2 // near top
  app.select_page_up() // should wrap around
  // When near top and cycling, should wrap to near bottom
  assert_true(app.selected_idx >= 20) // Should be near bottom
}

// =============================================================================
// Multi-line Header Tests
// =============================================================================

///|
test "count_lines: empty string" {
  assert_eq(count_lines(""), 0)
}

///|
test "count_lines: single line" {
  assert_eq(count_lines("hello"), 1)
}

///|
test "count_lines: multiple lines" {
  assert_eq(count_lines("line1\nline2\nline3"), 3)
}

///|
test "count_lines: trailing newline" {
  assert_eq(count_lines("line1\nline2\n"), 3) // "line1", "line2", "" (empty after)
}

///|
test "header: multi-line header" {
  let items = [@core.Item::new("test", 0)]
  let app = App::new(items, 80, 24, header="Header Line 1\nHeader Line 2")
  let output = app.render()
  assert_true(output.contains("Header Line 1"))
  assert_true(output.contains("Header Line 2"))
}
