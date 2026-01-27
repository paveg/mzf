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
/// Run the main application with optional initial query
fn run_app(
  items : Array[@core.Item],
  width : Int,
  height : Int,
  initial_query? : String = "",
) -> Unit {
  if items.length() == 0 {
    return
  }
  let app = @ui.App::new(items, width, height, initial_query~)

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
        Some(result) => println(result)
        None => ()
      }
    }
  })
}
