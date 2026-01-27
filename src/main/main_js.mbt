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

  // JS target: these options are not supported (require native file I/O or stdin)
  ignore(opts.read0) // Stdin reading not supported in JS
  ignore(opts.filter) // Non-interactive mode not supported in JS
  ignore(opts.history) // History file not supported in JS

  // Get terminal size
  let (width, term_height) = @io.get_terminal_size()
  // Use --height option if specified, otherwise use terminal height
  let height = if opts.height > 0 { opts.height } else { term_height }

  // JS target: use demo data (stdin pipe reading requires different approach)
  let raw_items = get_demo_items()

  // Apply --tac if specified (reverse input order)
  let items = if opts.tac { reverse_items(raw_items) } else { raw_items }
  // JS target: history not supported (no file I/O)
  let history : Array[String] = []
  run_app(
    items,
    width,
    height,
    initial_query=opts.query,
    reverse=opts.reverse,
    prompt=opts.prompt,
    pointer=opts.pointer,
    marker=opts.marker,
    multi=opts.multi,
    cycle=opts.cycle,
    no_sort=opts.no_sort,
    nth=opts.nth,
    delimiter=opts.delimiter,
    select_1=opts.select_1,
    exit_0=opts.exit_0,
    print0=opts.print0,
    exact=opts.exact,
    ignore_case=opts.ignore_case,
    header=opts.header,
    print_query=opts.print_query,
    with_nth=opts.with_nth,
    expect=opts.expect,
    ansi=opts.ansi,
    history~,
  )
}
