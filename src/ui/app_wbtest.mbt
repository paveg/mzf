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
