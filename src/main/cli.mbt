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
  let mut i = 1 // Skip program name
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      show_help = true
    } else if arg == "-v" || arg == "--version" {
      show_version = true
    } else if arg == "--reverse" {
      reverse = true
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
    }
    i = i + 1
  }
  { query, show_help, show_version, reverse, height, prompt, pointer, marker }
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
    "    -q, --query <QUERY>      Start with the given query\n" +
    "    --reverse                Display from top to bottom\n" +
    "    --height <N>             Maximum height (default: full screen)\n" +
    "    --prompt <STR>           Input prompt (default: \"> \")\n" +
    "    --pointer <STR>          Pointer to current line (default: \"> \")\n" +
    "    --marker <STR>           Multi-select marker (default: \"*\")\n" +
    "    -h, --help               Show this help message\n" +
    "    -v, --version            Show version information\n" +
    "\n" +
    "KEYBINDINGS:\n" +
    "    Enter        Select current item\n" +
    "    Tab          Toggle mark (multi-select)\n" +
    "    Esc, Ctrl-c  Cancel\n" +
    "    Up, Ctrl-p   Move up\n" +
    "    Down, Ctrl-n Move down\n" +
    "    Ctrl-u       Clear query\n" +
    "\n" +
    "EXAMPLES:\n" +
    "    find . -type f | mzf\n" +
    "    ls | mzf -q txt\n" +
    "    ls | mzf --reverse --pointer='▶ ' --marker='✓'\n"
  println(help)
}

///|
/// Print version
fn print_version() -> Unit {
  println("mzf 0.1.1")
}
