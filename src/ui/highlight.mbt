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
pub let ansi_magenta : String = "\u001b[35m"

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

///|
/// Color scheme for customizable colors
pub struct ColorScheme {
  fg : String // Foreground color for query text
  prompt : String // Prompt color
  pointer : String // Pointer/cursor color
  marker : String // Marker color
  info : String // Info line color
  header : String // Header color
  border : String // Border color
  hl : String // Highlight color for matches
}

///|
/// Default color scheme
pub fn ColorScheme::default() -> ColorScheme {
  {
    fg: "\u001b[37m", // White foreground for query
    prompt: ansi_yellow,
    pointer: ansi_cyan,
    marker: ansi_green,
    info: ansi_dim,
    header: ansi_magenta,
    border: ansi_dim,
    hl: ansi_cyan,
  }
}

///|
/// Map color name to ANSI code
fn color_name_to_ansi(name : String) -> String {
  match name {
    "black" => "\u001b[30m"
    "red" => "\u001b[31m"
    "green" => "\u001b[32m"
    "yellow" => "\u001b[33m"
    "blue" => "\u001b[34m"
    "magenta" => "\u001b[35m"
    "cyan" => "\u001b[36m"
    "white" => "\u001b[37m"
    "bright-black" | "dark-gray" => "\u001b[90m"
    "bright-red" => "\u001b[91m"
    "bright-green" => "\u001b[92m"
    "bright-yellow" => "\u001b[93m"
    "bright-blue" => "\u001b[94m"
    "bright-magenta" => "\u001b[95m"
    "bright-cyan" => "\u001b[96m"
    "bright-white" => "\u001b[97m"
    _ => "" // Invalid, return empty (use default)
  }
}

///|
/// Parse color specification string (e.g., "prompt:yellow,pointer:cyan")
pub fn ColorScheme::parse(spec : String) -> ColorScheme {
  let scheme = ColorScheme::default()
  if spec.length() == 0 {
    return scheme
  }
  // Split by comma
  let chars : Array[Char] = spec.iter().collect()
  let buf = StringBuilder::new()
  let pairs : Array[String] = []
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == ',' {
      pairs.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(chars[i])
    }
  }
  if buf.to_string().length() > 0 {
    pairs.push(buf.to_string())
  }
  // Parse each pair (key:value)
  let mut fg = scheme.fg
  let mut prompt = scheme.prompt
  let mut pointer = scheme.pointer
  let mut marker = scheme.marker
  let mut info = scheme.info
  let mut header = scheme.header
  let mut border = scheme.border
  let mut hl = scheme.hl
  for pair in pairs {
    let pair_chars : Array[Char] = pair.iter().collect()
    let key_buf = StringBuilder::new()
    let val_buf = StringBuilder::new()
    let mut in_value = false
    for j = 0; j < pair_chars.length(); j = j + 1 {
      if pair_chars[j] == ':' && not(in_value) {
        in_value = true
      } else if in_value {
        val_buf.write_char(pair_chars[j])
      } else {
        key_buf.write_char(pair_chars[j])
      }
    }
    let key = key_buf.to_string()
    let val = val_buf.to_string()
    let color = color_name_to_ansi(val)
    if color.length() > 0 {
      match key {
        "fg" => fg = color
        "prompt" => prompt = color
        "pointer" => pointer = color
        "marker" => marker = color
        "info" => info = color
        "header" => header = color
        "border" => border = color
        "hl" => hl = color
        _ => () // Unknown key, ignore
      }
    }
  }
  { fg, prompt, pointer, marker, info, header, border, hl }
}
