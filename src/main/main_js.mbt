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
  let (width, term_height) = @io.get_terminal_size()
  // Use --height option if specified, otherwise use terminal height
  let height = if opts.height > 0 { opts.height } else { term_height }

  // JS target: use demo data (stdin pipe reading requires different approach)
  let raw_items = get_demo_items()

  // Apply --tac if specified (reverse input order)
  let items = if opts.tac { reverse_items(raw_items) } else { raw_items }

  run_app(
    items,
    width,
    height,
    initial_query=opts.query,
    reverse=opts.reverse,
    prompt=opts.prompt,
    pointer=opts.pointer,
    marker=opts.marker,
    cycle=opts.cycle,
    no_sort=opts.no_sort,
    nth=opts.nth,
    delimiter=opts.delimiter,
    select_1=opts.select_1,
    exit_0=opts.exit_0,
    print0=opts.print0,
  )
}
