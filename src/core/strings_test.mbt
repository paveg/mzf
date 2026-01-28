// =============================================================================
// String Utilities Tests
// =============================================================================

///|
test "split_by_char: basic split" {
  let result = split_by_char("a:b:c", ':')
  assert_eq(result.length(), 3)
  assert_eq(result[0], "a")
  assert_eq(result[1], "b")
  assert_eq(result[2], "c")
}

///|
test "split_by_char: empty string" {
  let result = split_by_char("", ':')
  assert_eq(result.length(), 0)
}

///|
test "split_by_char: no delimiter" {
  let result = split_by_char("hello", ':')
  assert_eq(result.length(), 1)
  assert_eq(result[0], "hello")
}

///|
test "split_by_char: trailing delimiter" {
  let result = split_by_char("a:b:", ':')
  assert_eq(result.length(), 3)
  assert_eq(result[2], "")
}

///|
test "split_lines: basic split" {
  let result = split_lines("line1\nline2\nline3")
  assert_eq(result.length(), 3)
  assert_eq(result[0], "line1")
  assert_eq(result[1], "line2")
  assert_eq(result[2], "line3")
}

///|
test "split_lines: with carriage return" {
  let result = split_lines("line1\r\nline2\r\n")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "line1")
  assert_eq(result[1], "line2")
}

///|
test "split_lines: empty string" {
  let result = split_lines("")
  assert_eq(result.length(), 0)
}

///|
test "split_lines: single line no newline" {
  let result = split_lines("hello")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "hello")
}

///|
test "split_by_comma: basic" {
  let result = split_by_comma("1,2,3")
  assert_eq(result.length(), 3)
  assert_eq(result[0], "1")
  assert_eq(result[1], "2")
  assert_eq(result[2], "3")
}

///|
test "join_strings: basic" {
  let strings = ["a", "b", "c"]
  let result = join_strings(strings, "-")
  assert_eq(result, "a-b-c")
}

///|
test "join_strings: empty array" {
  let strings : Array[String] = []
  let result = join_strings(strings, "-")
  assert_eq(result, "")
}

///|
test "join_strings: single element" {
  let strings = ["only"]
  let result = join_strings(strings, "-")
  assert_eq(result, "only")
}

///|
test "count_lines: empty string" {
  assert_eq(count_lines(""), 0)
}

///|
test "count_lines: single line" {
  assert_eq(count_lines("hello"), 1)
}

///|
test "count_lines: multiple lines" {
  assert_eq(count_lines("a\nb\nc"), 3)
}
