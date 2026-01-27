///|
/// Scoring constants (based on fzf/skim)
let score_match : Int = 16

///|
let bonus_consecutive : Int = 16

///|
let bonus_boundary : Int = 8

///|
let bonus_camel_case : Int = 8

///|
let bonus_first_char : Int = 8

///|
let penalty_gap_start : Int = 3

///|
let penalty_gap_extension : Int = 1

///|
/// Check if a character is a word boundary character
fn is_boundary_char(c : Char) -> Bool {
  c == '_' || c == '-' || c == '/' || c == '.' || c == ' '
}

///|
/// Check if pattern contains any uppercase characters (for smart case)
fn has_uppercase(s : String) -> Bool {
  for c in s {
    if c >= 'A' && c <= 'Z' {
      return true
    }
  }
  false
}

///|
/// Convert char to lowercase
fn to_lower_char(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
/// Check if two chars match (considering case sensitivity)
fn chars_match(
  pattern_char : Char,
  text_char : Char,
  case_sensitive : Bool,
) -> Bool {
  if case_sensitive {
    pattern_char == text_char
  } else {
    to_lower_char(pattern_char) == to_lower_char(text_char)
  }
}

///|
/// Fuzzy match a pattern against text
/// Returns Some((score, match_positions)) if matched, None otherwise
pub fn fuzzy_match(pattern : String, text : String) -> (Int, Array[Int])? {
  if pattern.length() == 0 {
    return Some((0, []))
  }
  if text.length() == 0 {
    return None
  }
  let case_sensitive = has_uppercase(pattern)
  let pattern_chars : Array[Char] = pattern.iter().collect()
  let text_chars : Array[Char] = text.iter().collect()

  // First pass: check if all pattern chars exist in text (in order)
  let positions : Array[Int] = []
  let mut pattern_idx = 0
  for text_idx = 0; text_idx < text_chars.length(); text_idx = text_idx + 1 {
    if pattern_idx < pattern_chars.length() &&
      chars_match(
        pattern_chars[pattern_idx],
        text_chars[text_idx],
        case_sensitive,
      ) {
      positions.push(text_idx)
      pattern_idx = pattern_idx + 1
    }
  }

  // If not all pattern chars matched, return None
  if pattern_idx < pattern_chars.length() {
    return None
  }

  // Calculate score
  let score = calculate_score(text_chars, positions)
  Some((score, positions))
}

///|
/// Calculate score based on match positions
fn calculate_score(text_chars : Array[Char], positions : Array[Int]) -> Int {
  if positions.length() == 0 {
    return 0
  }
  let mut score = 0
  let mut prev_pos = -2 // -2 to ensure first char doesn't get consecutive bonus incorrectly
  for i = 0; i < positions.length(); i = i + 1 {
    let pos = positions[i]

    // Base score for match
    score = score + score_match

    // Bonus for first character match
    if pos == 0 {
      score = score + bonus_first_char
    }

    // Bonus for consecutive matches
    if pos == prev_pos + 1 {
      score = score + bonus_consecutive
    } else if prev_pos >= 0 {
      // Penalty for gap
      let gap = pos - prev_pos - 1
      score = score - penalty_gap_start - (gap - 1) * penalty_gap_extension
    }

    // Bonus for word boundary
    if pos > 0 {
      let prev_char = text_chars[pos - 1]
      let curr_char = text_chars[pos]

      // Boundary after separator
      if is_boundary_char(prev_char) {
        score = score + bonus_boundary
      }

      // CamelCase boundary (lowercase followed by uppercase)
      if prev_char >= 'a' &&
        prev_char <= 'z' &&
        curr_char >= 'A' &&
        curr_char <= 'Z' {
        score = score + bonus_camel_case
      }
    }
    prev_pos = pos
  }
  score
}

///|
/// Filter and score items based on pattern
pub fn filter_and_score(
  pattern : String,
  items : Array[Item],
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match fuzzy_match(pattern, item.text) {
      Some((score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      None => ()
    }
  }

  // Sort by score (descending)
  results.sort_by(fn(a, b) { b.score - a.score })
  results
}
