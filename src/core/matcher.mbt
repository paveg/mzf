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
/// Public version of has_uppercase for external use
pub fn has_uppercase_query(s : String) -> Bool {
  has_uppercase(s)
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

///|
/// Filter items without sorting (keep original order)
pub fn filter_without_sort(
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
  // No sorting - keep original order
  results
}

///|
/// Exact substring match - only match if pattern is a contiguous substring
/// Returns Some((score, match_positions)) if matched, None otherwise
pub fn exact_match(
  pattern : String,
  text : String,
  force_case_insensitive : Bool,
) -> (Int, Array[Int])? {
  if pattern.length() == 0 {
    return Some((0, []))
  }
  if text.length() == 0 || pattern.length() > text.length() {
    return None
  }
  // Use smart case unless force_case_insensitive is true
  let case_sensitive = if force_case_insensitive {
    false
  } else {
    has_uppercase(pattern)
  }
  let pattern_chars : Array[Char] = pattern.iter().collect()
  let text_chars : Array[Char] = text.iter().collect()

  // Find contiguous substring match
  for start = 0
      start <= text_chars.length() - pattern_chars.length()
      start = start + 1 {
    let mut matched = true
    for i = 0; i < pattern_chars.length(); i = i + 1 {
      if not(
          chars_match(pattern_chars[i], text_chars[start + i], case_sensitive),
        ) {
        matched = false
        break
      }
    }
    if matched {
      // Build positions array
      let positions : Array[Int] = []
      for i = 0; i < pattern_chars.length(); i = i + 1 {
        positions.push(start + i)
      }
      // Score based on match position (earlier = better)
      let score = 100 - start
      return Some((score, positions))
    }
  }
  None
}

///|
/// Filter with exact matching and score sorting
pub fn filter_exact(
  pattern : String,
  items : Array[Item],
  force_case_insensitive : Bool,
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match exact_match(pattern, item.text, force_case_insensitive) {
      Some((score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      None => ()
    }
  }
  // Sort by score (descending)
  results.sort_by(fn(a, b) { b.score - a.score })
  results
}

///|
/// Filter with exact matching without sorting
pub fn filter_exact_no_sort(
  pattern : String,
  items : Array[Item],
  force_case_insensitive : Bool,
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match exact_match(pattern, item.text, force_case_insensitive) {
      Some((score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      None => ()
    }
  }
  results
}

///|
/// Filter with fuzzy matching and forced case insensitivity
pub fn filter_and_score_ignore_case(
  pattern : String,
  items : Array[Item],
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match fuzzy_match_ignore_case(pattern, item.text) {
      Some((score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      None => ()
    }
  }
  // Sort by score (descending)
  results.sort_by(fn(a, b) { b.score - a.score })
  results
}

///|
/// Filter without sorting with forced case insensitivity
pub fn filter_without_sort_ignore_case(
  pattern : String,
  items : Array[Item],
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match fuzzy_match_ignore_case(pattern, item.text) {
      Some((score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      None => ()
    }
  }
  results
}

///|
/// Extended search term type
pub enum TermType {
  Fuzzy // default fuzzy match
  Exact // 'exact (substring)
  Prefix // ^prefix (starts with)
  Suffix // suffix$ (ends with)
  EqualExact // ^exact$ (exact full string match)
}

///|
/// Search term with type and inversion flag
pub struct SearchTerm {
  pattern : String
  term_type : TermType
  inverse : Bool // ! negation
}

///|
/// Parse a single search term (handles ^, $, ', ! modifiers)
fn parse_search_term(term : String) -> SearchTerm {
  if term.length() == 0 {
    return { pattern: "", term_type: Fuzzy, inverse: false }
  }
  let chars : Array[Char] = term.iter().collect()
  let mut start = 0
  let mut inverse = false

  // Check for negation prefix
  if chars[0] == '!' {
    inverse = true
    start = 1
  }
  if start >= chars.length() {
    return { pattern: "", term_type: Fuzzy, inverse }
  }

  // Check for prefix/suffix/exact modifiers
  let has_caret = chars[start] == '^'
  let has_dollar = chars[chars.length() - 1] == '$'
  let has_quote = chars[start] == '\''
  let (term_type, pattern_start, pattern_end) = if has_caret &&
    has_dollar &&
    chars.length() - start > 1 {
    // ^exact$ - full string match
    (EqualExact, start + 1, chars.length() - 1)
  } else if has_caret {
    // ^prefix - starts with
    (Prefix, start + 1, chars.length())
  } else if has_dollar && chars.length() > start + 1 {
    // suffix$ - ends with
    (Suffix, start, chars.length() - 1)
  } else if has_quote {
    // 'exact - substring exact match
    (Exact, start + 1, chars.length())
  } else {
    // default fuzzy
    (Fuzzy, start, chars.length())
  }

  // Extract pattern
  let buf = StringBuilder::new()
  for i = pattern_start; i < pattern_end; i = i + 1 {
    buf.write_char(chars[i])
  }
  { pattern: buf.to_string(), term_type, inverse }
}

///|
/// Parse query into search terms (space-separated = AND, | = OR groups)
/// Returns array of OR groups, each containing AND terms
pub fn parse_extended_query(query : String) -> Array[Array[SearchTerm]] {
  let or_groups : Array[Array[SearchTerm]] = []
  if query.length() == 0 {
    return or_groups
  }
  let chars : Array[Char] = query.iter().collect()
  let buf = StringBuilder::new()
  let current_and_terms : Array[SearchTerm] = []
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c == '|' {
      // End current term and start new OR group
      let term_str = buf.to_string()
      if term_str.length() > 0 {
        current_and_terms.push(parse_search_term(term_str))
      }
      buf.reset()
      if current_and_terms.length() > 0 {
        // Clone the array for the OR group
        let group : Array[SearchTerm] = []
        for t in current_and_terms {
          group.push(t)
        }
        or_groups.push(group)
        // Clear for next group - create new array
        current_and_terms.clear()
      }
    } else if c == ' ' {
      // End current term (AND separator)
      let term_str = buf.to_string()
      if term_str.length() > 0 {
        current_and_terms.push(parse_search_term(term_str))
      }
      buf.reset()
    } else {
      buf.write_char(c)
    }
  }

  // Handle last term
  let term_str = buf.to_string()
  if term_str.length() > 0 {
    current_and_terms.push(parse_search_term(term_str))
  }

  // Add last OR group
  if current_and_terms.length() > 0 {
    or_groups.push(current_and_terms)
  }
  or_groups
}

///|
/// Check if text matches a single search term
fn match_term(
  term : SearchTerm,
  text : String,
  case_sensitive : Bool,
) -> (Bool, Array[Int]) {
  if term.pattern.length() == 0 {
    return (not(term.inverse), [])
  }
  let pattern_chars : Array[Char] = term.pattern.iter().collect()
  let text_chars : Array[Char] = text.iter().collect()
  let (matched, positions) : (Bool, Array[Int]) = match term.term_type {
    Fuzzy => {
      // Use existing fuzzy match logic
      let result = if case_sensitive {
        fuzzy_match(term.pattern, text)
      } else {
        fuzzy_match_ignore_case(term.pattern, text)
      }
      match result {
        Some((_, pos)) => (true, pos)
        None => (false, [])
      }
    }
    Exact =>
      // Substring exact match
      match exact_match(term.pattern, text, not(case_sensitive)) {
        Some((_, pos)) => (true, pos)
        None => (false, [])
      }
    Prefix =>
      // Starts with
      if text_chars.length() < pattern_chars.length() {
        (false, [])
      } else {
        let mut ok = true
        let positions : Array[Int] = []
        for i = 0; i < pattern_chars.length(); i = i + 1 {
          if not(chars_match(pattern_chars[i], text_chars[i], case_sensitive)) {
            ok = false
            break
          }
          positions.push(i)
        }
        (ok, positions)
      }
    Suffix =>
      // Ends with
      if text_chars.length() < pattern_chars.length() {
        (false, [])
      } else {
        let start = text_chars.length() - pattern_chars.length()
        let mut ok = true
        let positions : Array[Int] = []
        for i = 0; i < pattern_chars.length(); i = i + 1 {
          if not(
              chars_match(
                pattern_chars[i],
                text_chars[start + i],
                case_sensitive,
              ),
            ) {
            ok = false
            break
          }
          positions.push(start + i)
        }
        (ok, positions)
      }
    EqualExact =>
      // Full string exact match
      if text_chars.length() != pattern_chars.length() {
        (false, [])
      } else {
        let mut ok = true
        let positions : Array[Int] = []
        for i = 0; i < pattern_chars.length(); i = i + 1 {
          if not(chars_match(pattern_chars[i], text_chars[i], case_sensitive)) {
            ok = false
            break
          }
          positions.push(i)
        }
        (ok, positions)
      }
  }

  // Apply inverse if needed
  if term.inverse {
    (not(matched), []) // No positions for inverse matches
  } else {
    (matched, positions)
  }
}

///|
/// Match text against extended query (OR of AND groups)
/// Returns (matched, score, positions)
pub fn extended_match(
  query : String,
  text : String,
  case_sensitive : Bool,
) -> (Bool, Int, Array[Int])? {
  let or_groups = parse_extended_query(query)
  if or_groups.length() == 0 {
    return Some((true, 0, []))
  }

  // Try each OR group - need any one to match
  for group in or_groups {
    let mut all_matched = true
    let mut total_score = 0
    let all_positions : Array[Int] = []

    // All terms in the group must match (AND logic)
    for term in group {
      let (matched, positions) = match_term(term, text, case_sensitive)
      if not(matched) {
        all_matched = false
        break
      }
      // Accumulate positions (avoid duplicates)
      for pos in positions {
        let mut found = false
        for existing in all_positions {
          if existing == pos {
            found = true
            break
          }
        }
        if not(found) {
          all_positions.push(pos)
        }
      }
      total_score = total_score + positions.length() * score_match
    }
    if all_matched {
      // Sort positions
      all_positions.sort_by(fn(a, b) { a - b })
      return Some((true, total_score, all_positions))
    }
  }
  None
}

///|
/// Filter with extended search syntax
pub fn filter_extended(
  query : String,
  items : Array[Item],
  case_sensitive : Bool,
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match extended_match(query, item.text, case_sensitive) {
      Some((true, score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      _ => ()
    }
  }
  // Sort by score (descending)
  results.sort_by(fn(a, b) { b.score - a.score })
  results
}

///|
/// Filter with extended search without sorting
pub fn filter_extended_no_sort(
  query : String,
  items : Array[Item],
  case_sensitive : Bool,
) -> Array[MatchResult] {
  let results : Array[MatchResult] = []
  for i = 0; i < items.length(); i = i + 1 {
    let item = items[i]
    match extended_match(query, item.text, case_sensitive) {
      Some((true, score, positions)) =>
        results.push(MatchResult::new(item, score, positions))
      _ => ()
    }
  }
  results
}

///|
/// Fuzzy match with forced case insensitivity
pub fn fuzzy_match_ignore_case(
  pattern : String,
  text : String,
) -> (Int, Array[Int])? {
  if pattern.length() == 0 {
    return Some((0, []))
  }
  if text.length() == 0 {
    return None
  }
  // Always case insensitive
  let case_sensitive = false
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
