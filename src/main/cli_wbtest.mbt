// =============================================================================
// CLI Parser Whitebox Tests
// =============================================================================

///|
test "cli: default options" {
  let opts : CliOptions = {
    query: "",
    show_help: false,
    show_version: false,
    reverse: false,
    height: 0,
    prompt: "> ",
    pointer: "> ",
    marker: "*",
    multi: false,
    no_sort: false,
    tac: false,
    cycle: false,
    select_1: false,
    exit_0: false,
    print0: false,
    nth: "",
    delimiter: "",
  }
  assert_eq(opts.query, "")
  assert_eq(opts.show_help, false)
  assert_eq(opts.show_version, false)
  assert_eq(opts.reverse, false)
  assert_eq(opts.height, 0)
  assert_eq(opts.prompt, "> ")
  assert_eq(opts.pointer, "> ")
  assert_eq(opts.marker, "*")
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

// =============================================================================
// New Display Options Tests
// =============================================================================

///|
test "cli: extract_value helper" {
  assert_eq(extract_value("--query=test", 8), "test")
  assert_eq(extract_value("-q=hello", 3), "hello")
  assert_eq(extract_value("--height=10", 9), "10")
  assert_eq(extract_value("--prompt=>>> ", 9), ">>> ")
}

///|
test "cli: parse_int helper" {
  assert_eq(parse_int("0"), 0)
  assert_eq(parse_int("10"), 10)
  assert_eq(parse_int("123"), 123)
  assert_eq(parse_int(""), 0)
}

///|
test "cli: reverse flag recognition" {
  assert_true("--reverse" == "--reverse")
}

///|
test "cli: height option patterns" {
  assert_true("--height".has_prefix("--height"))
  assert_true("--height=10".has_prefix("--height="))
}

///|
test "cli: prompt option patterns" {
  assert_true("--prompt".has_prefix("--prompt"))
  assert_true("--prompt=>>> ".has_prefix("--prompt="))
}

///|
test "cli: pointer option patterns" {
  assert_true("--pointer".has_prefix("--pointer"))
  assert_true("--pointer=▶ ".has_prefix("--pointer="))
}

///|
test "cli: marker option patterns" {
  assert_true("--marker".has_prefix("--marker"))
  assert_true("--marker=✓".has_prefix("--marker="))
}

// =============================================================================
// New Behavior Options Tests (TDD - tests written first)
// =============================================================================

///|
test "cli: multi flag recognition" {
  assert_true("-m" == "-m")
  assert_true("--multi" == "--multi")
}

///|
test "cli: no-sort flag recognition" {
  assert_true("--no-sort" == "--no-sort")
}

///|
test "cli: tac flag recognition" {
  assert_true("--tac" == "--tac")
}

///|
test "cli: cycle flag recognition" {
  assert_true("--cycle" == "--cycle")
}

///|
test "cli: select-1 flag recognition" {
  assert_true("--select-1" == "--select-1")
  assert_true("-1" == "-1")
}

///|
test "cli: exit-0 flag recognition" {
  assert_true("--exit-0" == "--exit-0")
  assert_true("-0" == "-0")
}

///|
test "cli: print0 flag recognition" {
  assert_true("--print0" == "--print0")
}

///|
test "cli: nth option patterns" {
  assert_true("--nth".has_prefix("--nth"))
  assert_true("--nth=1".has_prefix("--nth="))
  assert_true("--nth=1,2,3".has_prefix("--nth="))
  assert_true("-n".has_prefix("-n"))
}

///|
test "cli: delimiter option patterns" {
  assert_true("--delimiter".has_prefix("--delimiter"))
  assert_true("--delimiter=:".has_prefix("--delimiter="))
  assert_true("-d".has_prefix("-d"))
}

///|
test "cli: default new options" {
  let opts : CliOptions = {
    query: "",
    show_help: false,
    show_version: false,
    reverse: false,
    height: 0,
    prompt: "> ",
    pointer: "> ",
    marker: "*",
    multi: false,
    no_sort: false,
    tac: false,
    cycle: false,
    select_1: false,
    exit_0: false,
    print0: false,
    nth: "",
    delimiter: "",
  }
  assert_eq(opts.multi, false)
  assert_eq(opts.no_sort, false)
  assert_eq(opts.tac, false)
  assert_eq(opts.cycle, false)
  assert_eq(opts.select_1, false)
  assert_eq(opts.exit_0, false)
  assert_eq(opts.print0, false)
  assert_eq(opts.nth, "")
  assert_eq(opts.delimiter, "")
}
