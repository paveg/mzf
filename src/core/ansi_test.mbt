// =============================================================================
// ANSI Escape Code Processing Tests
// =============================================================================

///|
test "ansi: strip_ansi removes color codes" {
  // Red text: \e[31mred\e[0m
  let input = "\u001b[31mred\u001b[0m"
  let result = strip_ansi(input)
  assert_eq(result, "red")
}

///|
test "ansi: strip_ansi handles multiple colors" {
  // Red and green: \e[31mred\e[32mgreen\e[0m
  let input = "\u001b[31mred\u001b[32mgreen\u001b[0m"
  let result = strip_ansi(input)
  assert_eq(result, "redgreen")
}

///|
test "ansi: strip_ansi handles bold and colors" {
  // Bold red: \e[1;31mbold\e[0m
  let input = "\u001b[1;31mbold\u001b[0m"
  let result = strip_ansi(input)
  assert_eq(result, "bold")
}

///|
test "ansi: strip_ansi preserves plain text" {
  let input = "plain text without colors"
  let result = strip_ansi(input)
  assert_eq(result, "plain text without colors")
}

///|
test "ansi: strip_ansi handles empty string" {
  let result = strip_ansi("")
  assert_eq(result, "")
}

///|
test "ansi: strip_ansi handles cursor movement codes" {
  // Move cursor: \e[2A (up 2 lines)
  let input = "\u001b[2Atext"
  let result = strip_ansi(input)
  assert_eq(result, "text")
}

///|
test "ansi: extract_ansi_codes finds positions" {
  let input = "\u001b[31mred\u001b[0m"
  let codes = extract_ansi_codes(input)
  assert_eq(codes.length(), 2)
  assert_eq(codes[0].0, 0) // Position 0
  assert_eq(codes[0].1, "\u001b[31m") // Red color
  assert_eq(codes[1].0, 3) // After "red"
  assert_eq(codes[1].1, "\u001b[0m") // Reset
}

///|
test "ansi: insert_ansi_codes reconstructs text" {
  let stripped = "red"
  let codes : Array[(Int, String)] = [(0, "\u001b[31m"), (3, "\u001b[0m")]
  let result = insert_ansi_codes(stripped, codes)
  assert_eq(result, "\u001b[31mred\u001b[0m")
}

///|
test "ansi: roundtrip preserves text" {
  let original = "\u001b[31mred\u001b[32mgreen\u001b[0m"
  let stripped = strip_ansi(original)
  let codes = extract_ansi_codes(original)
  let reconstructed = insert_ansi_codes(stripped, codes)
  assert_eq(reconstructed, original)
}

///|
test "ansi: strip works with 256 color codes" {
  // 256-color: \e[38;5;196mtext\e[0m
  let input = "\u001b[38;5;196mcolorful\u001b[0m"
  let result = strip_ansi(input)
  assert_eq(result, "colorful")
}

///|
test "ansi: strip works with RGB color codes" {
  // RGB color: \e[38;2;255;0;0mtext\e[0m
  let input = "\u001b[38;2;255;0;0mrgb\u001b[0m"
  let result = strip_ansi(input)
  assert_eq(result, "rgb")
}
