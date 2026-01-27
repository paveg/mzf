///|
fn main {
  // Parse CLI options
  let opts = parse_args()
  if opts.show_help {
    print_help()
    return
  }
  if opts.show_version {
    print_version()
    return
  }

  // Get terminal size
  let (width, height) = @io.get_terminal_size()

  // JS target: use demo data (stdin pipe reading requires different approach)
  let items = get_demo_items()
  run_app(items, width, height, initial_query=opts.query)
}
