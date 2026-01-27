///|
/// Strip ANSI escape codes from a string
/// Returns the plain text without any escape sequences
pub fn strip_ansi(text : String) -> String {
  let chars : Array[Char] = text.iter().collect()
  let result = StringBuilder::new()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if chars[i] == '\u001b' {
      // Start of escape sequence
      i = i + 1
      if i < len && chars[i] == '[' {
        // CSI sequence: ESC [ ... final_byte
        i = i + 1
        // Skip parameter bytes (0x30-0x3F) and intermediate bytes (0x20-0x2F)
        while i < len {
          let c = chars[i]
          let code = c.to_uint()
          if code >= 0x40 && code <= 0x7E {
            // Final byte found, skip it and continue
            i = i + 1
            break
          }
          i = i + 1
        }
        // Non-CSI escape, skip the next char
      } else if i < len {
        i = i + 1
      }
    } else {
      result.write_char(chars[i])
      i = i + 1
    }
  }
  result.to_string()
}

///|
/// Extract ANSI codes and their positions from text
/// Returns array of (position_in_stripped_text, ansi_code) pairs
pub fn extract_ansi_codes(text : String) -> Array[(Int, String)] {
  let chars : Array[Char] = text.iter().collect()
  let codes : Array[(Int, String)] = []
  let len = chars.length()
  let mut i = 0
  let mut stripped_pos = 0
  while i < len {
    if chars[i] == '\u001b' {
      let start = i
      i = i + 1
      if i < len && chars[i] == '[' {
        i = i + 1
        while i < len {
          let c = chars[i]
          let code = c.to_uint()
          if code >= 0x40 && code <= 0x7E {
            i = i + 1
            break
          }
          i = i + 1
        }
      } else if i < len {
        i = i + 1
      }
      // Extract the ANSI code
      let code_buf = StringBuilder::new()
      for j = start; j < i; j = j + 1 {
        code_buf.write_char(chars[j])
      }
      codes.push((stripped_pos, code_buf.to_string()))
    } else {
      stripped_pos = stripped_pos + 1
      i = i + 1
    }
  }
  codes
}

///|
/// Reconstruct text with ANSI codes at given positions
pub fn insert_ansi_codes(
  stripped_text : String,
  codes : Array[(Int, String)],
) -> String {
  let chars : Array[Char] = stripped_text.iter().collect()
  let result = StringBuilder::new()
  let len = chars.length()

  // Group codes by position
  let mut code_idx = 0
  for i = 0; i <= len; i = i + 1 {
    // Insert all codes at this position
    while code_idx < codes.length() && codes[code_idx].0 == i {
      result.write_string(codes[code_idx].1)
      code_idx = code_idx + 1
    }
    if i < len {
      result.write_char(chars[i])
    }
  }
  result.to_string()
}
