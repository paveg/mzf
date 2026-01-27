///|
/// ANSI escape codes for highlighting
pub let ansi_reset : String = "\u001b[0m"

///|
pub let ansi_bold : String = "\u001b[1m"

///|
pub let ansi_cyan : String = "\u001b[36m"

///|
pub let ansi_yellow : String = "\u001b[33m"

///|
pub let ansi_green : String = "\u001b[32m"

///|
pub let ansi_dim : String = "\u001b[2m"

///|
pub let ansi_reverse : String = "\u001b[7m"

///|
/// Generate highlighted text with match positions marked
pub fn highlight_text(
  text : String,
  match_positions : Array[Int],
  highlight_color : String,
) -> String {
  if match_positions.length() == 0 {
    return text
  }
  let chars : Array[Char] = text.iter().collect()
  let buf = StringBuilder::new()
  let positions_set : Array[Bool] = Array::make(chars.length(), false)

  // Mark positions
  for pos in match_positions {
    if pos >= 0 && pos < chars.length() {
      positions_set[pos] = true
    }
  }

  // Build highlighted string
  let mut in_highlight = false
  for i = 0; i < chars.length(); i = i + 1 {
    if positions_set[i] {
      if not(in_highlight) {
        buf.write_string(highlight_color)
        buf.write_string(ansi_bold)
        in_highlight = true
      }
      buf.write_char(chars[i])
    } else {
      if in_highlight {
        buf.write_string(ansi_reset)
        in_highlight = false
      }
      buf.write_char(chars[i])
    }
  }
  if in_highlight {
    buf.write_string(ansi_reset)
  }
  buf.to_string()
}

///|
/// Highlight match result for display
pub fn highlight_match_result(result : @core.MatchResult) -> String {
  highlight_text(result.item.text, result.match_positions, ansi_cyan)
}
