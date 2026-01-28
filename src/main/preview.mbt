// =============================================================================
// Preview command execution and placeholder substitution
// =============================================================================

///|
/// Escape a string for safe shell usage (single-quote escaping)
pub fn shell_escape(s : String) -> String {
  let buf = StringBuilder::new()
  buf.write_char('\'')
  for c in s {
    if c == '\'' {
      // End quote, add escaped quote, start quote again
      buf.write_string("'\\''")
    } else {
      buf.write_char(c)
    }
  }
  buf.write_char('\'')
  buf.to_string()
}

///|
/// Substitute placeholders in preview command
/// Supported placeholders:
///   {} - Current line (shell-escaped)
///   {f} - Current line (quoted for file paths)
///   {n} - Line number (1-indexed)
///   {q} - Current query string (shell-escaped)
///   {+} - All marked items (space-separated, shell-escaped)
///   {+n} - Line numbers of all marked items (space-separated)
pub fn substitute_placeholders(
  cmd : String,
  item : String,
  line_num : Int,
  query : String,
  marked_items : Array[String],
  marked_indices : Array[Int],
) -> String {
  let chars : Array[Char] = cmd.iter().collect()
  let buf = StringBuilder::new()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if chars[i] == '{' && i + 1 < len {
      // Check for placeholder patterns
      if chars[i + 1] == '}' {
        // {} - current item (escaped)
        buf.write_string(shell_escape(item))
        i = i + 2
        continue
      } else if i + 2 < len && chars[i + 1] == 'f' && chars[i + 2] == '}' {
        // {f} - quoted current item
        buf.write_string(shell_escape(item))
        i = i + 3
        continue
      } else if i + 2 < len && chars[i + 1] == 'n' && chars[i + 2] == '}' {
        // {n} - line number
        buf.write_string(line_num.to_string())
        i = i + 3
        continue
      } else if i + 2 < len && chars[i + 1] == 'q' && chars[i + 2] == '}' {
        // {q} - query
        buf.write_string(shell_escape(query))
        i = i + 3
        continue
      } else if i + 2 < len && chars[i + 1] == '+' && chars[i + 2] == '}' {
        // {+} - all marked items
        let marked_buf = StringBuilder::new()
        for j = 0; j < marked_items.length(); j = j + 1 {
          if j > 0 {
            marked_buf.write_char(' ')
          }
          marked_buf.write_string(shell_escape(marked_items[j]))
        }
        buf.write_string(marked_buf.to_string())
        i = i + 3
        continue
      } else if i + 3 < len &&
        chars[i + 1] == '+' &&
        chars[i + 2] == 'n' &&
        chars[i + 3] == '}' {
        // {+n} - line numbers of marked items
        let idx_buf = StringBuilder::new()
        for j = 0; j < marked_indices.length(); j = j + 1 {
          if j > 0 {
            idx_buf.write_char(' ')
          }
          // Convert 0-indexed to 1-indexed
          idx_buf.write_string((marked_indices[j] + 1).to_string())
        }
        buf.write_string(idx_buf.to_string())
        i = i + 4
        continue
      }
    }
    buf.write_char(chars[i])
    i = i + 1
  }
  buf.to_string()
}

///|
/// Parse preview window spec (e.g., "right:50%", "bottom:40%")
/// Returns (position, size_percent)
pub fn parse_preview_window(spec : String) -> (String, Int) {
  let chars : Array[Char] = spec.iter().collect()
  let pos_buf = StringBuilder::new()
  let size_buf = StringBuilder::new()
  let mut in_size = false
  for c in chars {
    if c == ':' {
      in_size = true
    } else if in_size {
      if c >= '0' && c <= '9' {
        size_buf.write_char(c)
      }
      // Skip '%'
    } else {
      pos_buf.write_char(c)
    }
  }
  let position = pos_buf.to_string()
  let size_str = size_buf.to_string()
  let size = if size_str.length() > 0 {
    parse_preview_int(size_str)
  } else {
    50 // default 50%
  }
  (position, size)
}

///|
fn parse_preview_int(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}
