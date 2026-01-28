///|
/// CLI options
struct CliOptions {
  query : String // Initial query (-q, --query)
  show_help : Bool // Show help (-h, --help)
  show_version : Bool // Show version (-v, --version)
  reverse : Bool // Reverse list order (--reverse)
  height : Int // Height in lines, 0 = full screen (--height)
  prompt : String // Prompt string (--prompt)
  pointer : String // Pointer/cursor string (--pointer)
  marker : String // Marker string for multi-select (--marker)
  // Behavior options
  multi : Bool // Enable multi-select (-m, --multi)
  no_sort : Bool // Don't sort results (--no-sort)
  tac : Bool // Reverse input order (--tac)
  cycle : Bool // Enable cyclic scroll (--cycle)
  select_1 : Bool // Auto-select if single match (-1, --select-1)
  exit_0 : Bool // Exit if no match (-0, --exit-0)
  print0 : Bool // Use NUL separator (--print0)
  nth : String // Field index for matching (-n, --nth)
  delimiter : String // Field delimiter (-d, --delimiter)
  // Search options
  extended : Bool // Extended search mode (-x, --extended)
  exact : Bool // Exact match mode (-e, --exact)
  ignore_case : Bool // Force case insensitive (-i, --ignore-case)
  // Input/Output options
  read0 : Bool // Read NUL-delimited input (--read0)
  filter : String // Non-interactive filter mode (-f, --filter)
  print_query : Bool // Print query as first line (--print-query)
  header : String // Header string (--header)
  header_lines : Int // Number of header lines from input (--header-lines)
  // Display transformation
  with_nth : String // Field index for display (--with-nth)
  // Key handling
  expect : String // Expected keys to abort (--expect)
  // Advanced options
  ansi : Bool // Enable ANSI color processing (--ansi)
  history : String // History file path (--history)
  history_size : Int // Maximum history entries (--history-size, default 1000)
  // Display options
  border : String // Border style (--border: none, rounded, sharp, horizontal)
  info : String // Info line style (--info: default, hidden, inline)
  layout : String // Layout (--layout: default, reverse, reverse-list)
  color : String // Color scheme (--color: prompt:yellow,pointer:cyan,...)
  // Preview options
  preview : String // Preview command (--preview)
  preview_window : String // Preview window spec (--preview-window: right:50%)
  // Shell integration options
  shell_bash : Bool // Output bash integration script (--bash)
  shell_zsh : Bool // Output zsh integration script (--zsh)
  shell_fish : Bool // Output fish integration script (--fish)
}

///|
/// Extract value after prefix (e.g., "--query=value" -> "value")
fn extract_value(arg : String, prefix_len : Int) -> String {
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = prefix_len; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  buf.to_string()
}

///|
/// Parse command line arguments
fn parse_args() -> CliOptions {
  let args = @env.args()
  let mut query = ""
  let mut show_help = false
  let mut show_version = false
  let mut reverse = false
  let mut height = 0
  let mut prompt = "> "
  let mut pointer = "> "
  let mut marker = "*"
  let mut multi = false
  let mut no_sort = false
  let mut tac = false
  let mut cycle = false
  let mut select_1 = false
  let mut exit_0 = false
  let mut print0 = false
  let mut nth = ""
  let mut delimiter = ""
  let mut extended = false
  let mut exact = false
  let mut ignore_case = false
  let mut read0 = false
  let mut filter = ""
  let mut print_query = false
  let mut header = ""
  let mut header_lines = 0
  let mut with_nth = ""
  let mut expect = ""
  let mut ansi = false
  let mut history = ""
  let mut history_size = 1000 // Default like fzf
  let mut border = "none"
  let mut info = "default"
  let mut layout = "default"
  let mut color = ""
  let mut preview = ""
  let mut preview_window = "right:50%"
  let mut shell_bash = false
  let mut shell_zsh = false
  let mut shell_fish = false
  let mut i = 1 // Skip program name
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      show_help = true
    } else if arg == "-v" || arg == "--version" {
      show_version = true
    } else if arg == "--reverse" {
      reverse = true
    } else if arg == "-m" || arg == "--multi" {
      multi = true
    } else if arg == "--no-sort" {
      no_sort = true
    } else if arg == "--tac" {
      tac = true
    } else if arg == "--cycle" {
      cycle = true
    } else if arg == "-1" || arg == "--select-1" {
      select_1 = true
    } else if arg == "-0" || arg == "--exit-0" {
      exit_0 = true
    } else if arg == "--print0" {
      print0 = true
    } else if arg == "-x" || arg == "--extended" {
      extended = true
    } else if arg == "-e" || arg == "--exact" {
      exact = true
    } else if arg == "-i" || arg == "--ignore-case" {
      ignore_case = true
    } else if arg == "--read0" {
      read0 = true
    } else if arg == "--print-query" {
      print_query = true
    } else if arg == "-q" || arg == "--query" {
      i = i + 1
      if i < args.length() {
        query = args[i]
      }
    } else if arg.has_prefix("--query=") {
      query = extract_value(arg, 8)
    } else if arg.has_prefix("-q=") {
      query = extract_value(arg, 3)
    } else if arg == "--height" {
      i = i + 1
      if i < args.length() {
        height = parse_int(args[i])
      }
    } else if arg.has_prefix("--height=") {
      height = parse_int(extract_value(arg, 9))
    } else if arg == "--prompt" {
      i = i + 1
      if i < args.length() {
        prompt = args[i]
      }
    } else if arg.has_prefix("--prompt=") {
      prompt = extract_value(arg, 9)
    } else if arg == "--pointer" {
      i = i + 1
      if i < args.length() {
        pointer = args[i]
      }
    } else if arg.has_prefix("--pointer=") {
      pointer = extract_value(arg, 10)
    } else if arg == "--marker" {
      i = i + 1
      if i < args.length() {
        marker = args[i]
      }
    } else if arg.has_prefix("--marker=") {
      marker = extract_value(arg, 9)
    } else if arg == "-n" || arg == "--nth" {
      i = i + 1
      if i < args.length() {
        nth = args[i]
      }
    } else if arg.has_prefix("--nth=") {
      nth = extract_value(arg, 6)
    } else if arg.has_prefix("-n=") {
      nth = extract_value(arg, 3)
    } else if arg == "-d" || arg == "--delimiter" {
      i = i + 1
      if i < args.length() {
        delimiter = args[i]
      }
    } else if arg.has_prefix("--delimiter=") {
      delimiter = extract_value(arg, 12)
    } else if arg.has_prefix("-d=") {
      delimiter = extract_value(arg, 3)
    } else if arg == "-f" || arg == "--filter" {
      i = i + 1
      if i < args.length() {
        filter = args[i]
      }
    } else if arg.has_prefix("--filter=") {
      filter = extract_value(arg, 9)
    } else if arg.has_prefix("-f=") {
      filter = extract_value(arg, 3)
    } else if arg == "--header" {
      i = i + 1
      if i < args.length() {
        header = args[i]
      }
    } else if arg.has_prefix("--header=") {
      header = extract_value(arg, 9)
    } else if arg == "--header-lines" {
      i = i + 1
      if i < args.length() {
        header_lines = parse_int(args[i])
      }
    } else if arg.has_prefix("--header-lines=") {
      header_lines = parse_int(extract_value(arg, 15))
    } else if arg == "--with-nth" {
      i = i + 1
      if i < args.length() {
        with_nth = args[i]
      }
    } else if arg.has_prefix("--with-nth=") {
      with_nth = extract_value(arg, 11)
    } else if arg == "--expect" {
      i = i + 1
      if i < args.length() {
        expect = args[i]
      }
    } else if arg.has_prefix("--expect=") {
      expect = extract_value(arg, 9)
    } else if arg == "--ansi" {
      ansi = true
    } else if arg == "--history" {
      i = i + 1
      if i < args.length() {
        history = args[i]
      }
    } else if arg.has_prefix("--history=") {
      history = extract_value(arg, 10)
    } else if arg == "--history-size" {
      i = i + 1
      if i < args.length() {
        history_size = parse_int(args[i])
      }
    } else if arg.has_prefix("--history-size=") {
      history_size = parse_int(extract_value(arg, 15))
    } else if arg == "--border" {
      i = i + 1
      if i < args.length() {
        border = args[i]
      }
    } else if arg.has_prefix("--border=") {
      border = extract_value(arg, 9)
    } else if arg == "--info" {
      i = i + 1
      if i < args.length() {
        info = args[i]
      }
    } else if arg.has_prefix("--info=") {
      info = extract_value(arg, 7)
    } else if arg == "--layout" {
      i = i + 1
      if i < args.length() {
        layout = args[i]
      }
    } else if arg.has_prefix("--layout=") {
      layout = extract_value(arg, 9)
    } else if arg == "--color" {
      i = i + 1
      if i < args.length() {
        color = args[i]
      }
    } else if arg.has_prefix("--color=") {
      color = extract_value(arg, 8)
    } else if arg == "--preview" {
      i = i + 1
      if i < args.length() {
        preview = args[i]
      }
    } else if arg.has_prefix("--preview=") {
      preview = extract_value(arg, 10)
    } else if arg == "--preview-window" {
      i = i + 1
      if i < args.length() {
        preview_window = args[i]
      }
    } else if arg.has_prefix("--preview-window=") {
      preview_window = extract_value(arg, 17)
    } else if arg == "--bash" {
      shell_bash = true
    } else if arg == "--zsh" {
      shell_zsh = true
    } else if arg == "--fish" {
      shell_fish = true
    }
    i = i + 1
  }
  {
    query,
    show_help,
    show_version,
    reverse,
    height,
    prompt,
    pointer,
    marker,
    multi,
    no_sort,
    tac,
    cycle,
    select_1,
    exit_0,
    print0,
    nth,
    delimiter,
    extended,
    exact,
    ignore_case,
    read0,
    filter,
    print_query,
    header,
    header_lines,
    with_nth,
    expect,
    ansi,
    history,
    history_size,
    border,
    info,
    layout,
    color,
    preview,
    preview_window,
    shell_bash,
    shell_zsh,
    shell_fish,
  }
}

///|
/// Parse integer from string (simple implementation)
fn parse_int(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

///|
/// Print help message
fn print_help() -> Unit {
  let help = "mzf - MoonBit Fuzzy Finder\n" +
    "\n" +
    "USAGE:\n" +
    "    command | mzf [OPTIONS]\n" +
    "\n" +
    "OPTIONS:\n" +
    "  Search:\n" +
    "    -x, --extended           Extended search mode (^, $, ', !)\n" +
    "    -q, --query <QUERY>      Start with the given query\n" +
    "    -e, --exact              Exact-match mode (substring)\n" +
    "    -i, --ignore-case        Force case-insensitive matching\n" +
    "    -n, --nth <N[,M,...]>    Match only in specified fields\n" +
    "    -d, --delimiter <STR>    Field delimiter (default: none)\n" +
    "\n" +
    "  Display:\n" +
    "    --reverse                Display from top to bottom\n" +
    "    --height <N>             Maximum height (default: full screen)\n" +
    "    --prompt <STR>           Input prompt (default: \"> \")\n" +
    "    --pointer <STR>          Pointer to current line (default: \"> \")\n" +
    "    --marker <STR>           Multi-select marker (default: \"*\")\n" +
    "    --header <STR>           Header string to display\n" +
    "    --header-lines <N>       First N lines of input as header\n" +
    "    --with-nth <N[,M,...]>   Transform display using field indices\n" +
    "    --ansi                   Enable ANSI color processing\n" +
    "    --border <STYLE>         Border style (none, rounded, sharp, horizontal)\n" +
    "    --info <STYLE>           Info line style (default, hidden, inline)\n" +
    "    --layout <LAYOUT>        Layout (default, reverse, reverse-list)\n" +
    "    --color <SPEC>           Color scheme (prompt:yellow,pointer:cyan,...)\n" +
    "\n" +
    "  Preview:\n" +
    "    --preview <CMD>          Command to preview selected item (use {} for item)\n" +
    "    --preview-window <SPEC>  Preview window layout (right:50%, bottom:40%)\n" +
    "\n" +
    "  Behavior:\n" +
    "    -m, --multi              Enable multi-select (Tab to mark)\n" +
    "    --no-sort                Don't sort results by score\n" +
    "    --tac                    Reverse input order\n" +
    "    --cycle                  Enable cyclic scroll\n" +
    "    -1, --select-1           Auto-select if single match\n" +
    "    -0, --exit-0             Exit immediately if no match\n" +
    "    --expect <KEYS>          Comma-separated keys to abort\n" +
    "\n" +
    "  Input/Output:\n" +
    "    --read0                  Read NUL-delimited input\n" +
    "    --print0                 Use NUL separator for output\n" +
    "    -f, --filter <QUERY>     Filter mode (non-interactive)\n" +
    "    --print-query            Print query as first line of output\n" +
    "    --history <FILE>         History file path\n" +
    "    --history-size <N>       Maximum history size (default: 1000)\n" +
    "\n" +
    "  Shell Integration:\n" +
    "    --bash                   Output bash integration script\n" +
    "    --zsh                    Output zsh integration script\n" +
    "    --fish                   Output fish integration script\n" +
    "\n" +
    "  Other:\n" +
    "    -h, --help               Show this help message\n" +
    "    -v, --version            Show version information\n" +
    "\n" +
    "KEYBINDINGS:\n" +
    "    Enter        Select current item\n" +
    "    Tab          Toggle mark (requires -m)\n" +
    "    Esc, Ctrl-c  Cancel\n" +
    "    Up           Move up / History prev (with --history)\n" +
    "    Down         Move down / History next (with --history)\n" +
    "    Ctrl-p       History prev (with --history) / Move up\n" +
    "    Ctrl-n       History next (with --history) / Move down\n" +
    "    Ctrl-u       Clear query\n" +
    "\n" +
    "EXAMPLES:\n" +
    "    find . -type f | mzf\n" +
    "    ls | mzf -q txt\n" +
    "    ls | mzf -m --reverse --pointer='▶ ' --marker='✓'\n" +
    "    ps aux | mzf -n 1,2 -d ' '  # Match process name and user\n" +
    "    echo -e 'foo\\nbar' | mzf -e -q oo  # Exact match\n" +
    "    find . | mzf -f src  # Filter mode (non-interactive)\n" +
    "    ls --color=always | mzf --ansi  # Preserve colors\n" +
    "\n" +
    "SHELL INTEGRATION:\n" +
    "    # Bash: Add to ~/.bashrc\n" +
    "    eval \"$(mzf --bash)\"\n" +
    "\n" +
    "    # Zsh: Add to ~/.zshrc\n" +
    "    source <(mzf --zsh)\n" +
    "\n" +
    "    # Fish: Add to ~/.config/fish/config.fish\n" +
    "    mzf --fish | source\n" +
    "\n" +
    "    Key bindings after sourcing:\n" +
    "      Ctrl-T  File selection (paste to command line)\n" +
    "      Ctrl-R  History search\n" +
    "      Alt-C   cd to selected directory\n" +
    "\n" +
    "    Environment variables:\n" +
    "      MZF_CTRL_T_COMMAND    File listing command\n" +
    "      MZF_CTRL_T_OPTS       Options for Ctrl-T\n" +
    "      MZF_ALT_C_COMMAND     Directory listing command\n" +
    "      MZF_ALT_C_OPTS        Options for Alt-C\n" +
    "      MZF_CTRL_R_OPTS       Options for Ctrl-R\n" +
    "      MZF_COMPLETION_TRIGGER  Completion trigger (default: **)\n"
  println(help)
}

///|
/// Print version
fn print_version() -> Unit {
  println("mzf 0.2.0")
}
