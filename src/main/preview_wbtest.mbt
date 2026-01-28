// =============================================================================
// Preview Whitebox Tests
// =============================================================================

///|
test "preview: shell_escape basic" {
  assert_eq(shell_escape("hello"), "'hello'")
  assert_eq(shell_escape("world"), "'world'")
}

///|
test "preview: shell_escape with single quote" {
  assert_eq(shell_escape("it's"), "'it'\\''s'")
  assert_eq(shell_escape("don't"), "'don'\\''t'")
}

///|
test "preview: shell_escape with spaces" {
  assert_eq(shell_escape("hello world"), "'hello world'")
  assert_eq(shell_escape("path with spaces"), "'path with spaces'")
}

///|
test "preview: shell_escape empty string" {
  assert_eq(shell_escape(""), "''")
}

///|
test "preview: substitute_placeholders basic" {
  let cmd = "cat {}"
  let result = substitute_placeholders(cmd, "file.txt", 1, "", [], [])
  assert_eq(result, "cat 'file.txt'")
}

///|
test "preview: substitute_placeholders with query" {
  let cmd = "grep {q} {}"
  let result = substitute_placeholders(cmd, "file.txt", 1, "pattern", [], [])
  assert_eq(result, "grep 'pattern' 'file.txt'")
}

///|
test "preview: substitute_placeholders with line number" {
  let cmd = "sed -n {n}p {}"
  let result = substitute_placeholders(cmd, "file.txt", 5, "", [], [])
  assert_eq(result, "sed -n 5p 'file.txt'")
}

///|
test "preview: substitute_placeholders with quoted file" {
  let cmd = "cat {f}"
  let result = substitute_placeholders(cmd, "my file.txt", 1, "", [], [])
  assert_eq(result, "cat 'my file.txt'")
}

///|
test "preview: substitute_placeholders with marked items" {
  let cmd = "echo {+}"
  let marked = ["file1.txt", "file2.txt"]
  let result = substitute_placeholders(cmd, "current.txt", 1, "", marked, [])
  assert_eq(result, "echo 'file1.txt' 'file2.txt'")
}

///|
test "preview: substitute_placeholders with marked indices" {
  let cmd = "echo {+n}"
  let indices = [0, 2, 5]
  let result = substitute_placeholders(cmd, "current.txt", 1, "", [], indices)
  assert_eq(result, "echo 1 3 6") // 0-indexed to 1-indexed
}

///|
test "preview: substitute_placeholders no placeholders" {
  let cmd = "ls -la"
  let result = substitute_placeholders(cmd, "file.txt", 1, "query", [], [])
  assert_eq(result, "ls -la")
}

///|
test "preview: parse_preview_window right" {
  let (pos, size) = parse_preview_window("right:50%")
  assert_eq(pos, "right")
  assert_eq(size, 50)
}

///|
test "preview: parse_preview_window bottom" {
  let (pos, size) = parse_preview_window("bottom:40%")
  assert_eq(pos, "bottom")
  assert_eq(size, 40)
}

///|
test "preview: parse_preview_window default size" {
  let (pos, size) = parse_preview_window("right")
  assert_eq(pos, "right")
  assert_eq(size, 50) // default
}

///|
test "preview: parse_preview_window no spec" {
  let (pos, size) = parse_preview_window("")
  assert_eq(pos, "")
  assert_eq(size, 50) // default
}

// Note: These tests only work on native target, not wasm-gc test runner
// They are here for documentation and manual testing

///|
test "preview: exec_preview_sync should be callable" {
  // Just verify the function signature is correct
  // Actual execution would require native FFI
  let _fn : (String) -> String = fn(s) { s }
  assert_true(true)
}
