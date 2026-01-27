///|
/// CLI options
struct CliOptions {
  query : String // Initial query (-q, --query)
  show_help : Bool // Show help (-h, --help)
  show_version : Bool // Show version (-v, --version)
}

///|
/// Parse command line arguments
fn parse_args() -> CliOptions {
  let args = @env.args()
  let mut query = ""
  let mut show_help = false
  let mut show_version = false
  let mut i = 1 // Skip program name
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      show_help = true
    } else if arg == "-v" || arg == "--version" {
      show_version = true
    } else if arg == "-q" || arg == "--query" {
      i = i + 1
      if i < args.length() {
        query = args[i]
      }
    } else if arg.has_prefix("--query=") {
      // Extract value after "="
      let chars : Array[Char] = arg.iter().collect()
      let buf = StringBuilder::new()
      for j = 8; j < chars.length(); j = j + 1 {
        buf.write_char(chars[j])
      }
      query = buf.to_string()
    } else if arg.has_prefix("-q=") {
      let chars : Array[Char] = arg.iter().collect()
      let buf = StringBuilder::new()
      for j = 3; j < chars.length(); j = j + 1 {
        buf.write_char(chars[j])
      }
      query = buf.to_string()
    }
    i = i + 1
  }
  { query, show_help, show_version }
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
    "    -q, --query <QUERY>    Start with the given query\n" +
    "    -h, --help             Show this help message\n" +
    "    -v, --version          Show version information\n" +
    "\n" +
    "KEYBINDINGS:\n" +
    "    Enter        Select current item\n" +
    "    Esc, Ctrl-c  Cancel\n" +
    "    Up, Ctrl-p   Move up\n" +
    "    Down, Ctrl-n Move down\n" +
    "    Ctrl-u       Clear query\n" +
    "\n" +
    "EXAMPLES:\n" +
    "    find . -type f | mzf\n" +
    "    ls | mzf -q txt\n"
  println(help)
}

///|
/// Print version
fn print_version() -> Unit {
  println("mzf 0.1.0")
}
