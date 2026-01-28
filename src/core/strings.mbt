///|
/// Split string by a single character delimiter
pub fn split_by_char(text : String, delimiter : Char) -> Array[String] {
  let fields : Array[String] = []
  if text.length() == 0 {
    return fields
  }
  let chars : Array[Char] = text.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == delimiter {
      fields.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(chars[i])
    }
  }
  // Add last field
  fields.push(buf.to_string())
  fields
}

///|
/// Split string by newlines, handling both \n and \r\n
pub fn split_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  if text.length() == 0 {
    return lines
  }
  let chars : Array[Char] = text.iter().collect()
  let buf = StringBuilder::new()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '\n' {
      let line = buf.to_string()
      if line.length() > 0 {
        lines.push(line)
      }
      buf.reset()
    } else if chars[i] != '\r' {
      buf.write_char(chars[i])
    }
  }
  // Handle last line without newline
  let last = buf.to_string()
  if last.length() > 0 {
    lines.push(last)
  }
  lines
}

///|
/// Split string by comma
pub fn split_by_comma(text : String) -> Array[String] {
  split_by_char(text, ',')
}

///|
/// Join strings with a separator
pub fn join_strings(strings : Array[String], separator : String) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < strings.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(separator)
    }
    buf.write_string(strings[i])
  }
  buf.to_string()
}

///|
/// Count the number of lines in a string
pub fn count_lines(text : String) -> Int {
  if text.length() == 0 {
    return 0
  }
  let mut count = 1
  for c in text {
    if c == '\n' {
      count = count + 1
    }
  }
  count
}
