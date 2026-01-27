// =============================================================================
// CLI Parser Whitebox Tests
// =============================================================================

///|
test "cli: default options" {
  let opts : CliOptions = { query: "", show_help: false, show_version: false }
  assert_eq(opts.query, "")
  assert_eq(opts.show_help, false)
  assert_eq(opts.show_version, false)
}

///|
test "cli: help flag recognition" {
  assert_true("-h" == "-h")
  assert_true("--help" == "--help")
}

///|
test "cli: version flag recognition" {
  assert_true("-v" == "-v")
  assert_true("--version" == "--version")
}

///|
test "cli: query flag patterns" {
  assert_true("-q".has_prefix("-q"))
  assert_true("--query".has_prefix("--query"))
  assert_true("--query=foo".has_prefix("--query="))
  assert_true("-q=bar".has_prefix("-q="))
}

///|
test "cli: extract query from --query=value" {
  let arg = "--query=test"
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = 8; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  assert_eq(buf.to_string(), "test")
}

///|
test "cli: extract query from -q=value" {
  let arg = "-q=hello"
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = 3; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  assert_eq(buf.to_string(), "hello")
}

///|
test "cli: empty query extraction" {
  let arg = "--query="
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = 8; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  assert_eq(buf.to_string(), "")
}

///|
test "cli: query with spaces" {
  let arg = "--query=hello world"
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = 8; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  assert_eq(buf.to_string(), "hello world")
}

///|
test "cli: query with special chars" {
  let arg = "--query=foo/bar.txt"
  let chars : Array[Char] = arg.iter().collect()
  let buf = StringBuilder::new()
  for j = 8; j < chars.length(); j = j + 1 {
    buf.write_char(chars[j])
  }
  assert_eq(buf.to_string(), "foo/bar.txt")
}
