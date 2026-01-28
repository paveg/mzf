// =============================================================================
// Common logic shared between native and JS main files
// =============================================================================

///|
/// Parse string content into Items (used by both native and JS stdin parsing)
pub fn parse_content_to_items(
  content : String,
  read0 : Bool,
) -> Array[@core.Item] {
  let items : Array[@core.Item] = []
  if content.length() == 0 {
    return items
  }
  let delimiter = if read0 { '\u0000' } else { '\n' }
  let chars : Array[Char] = content.iter().collect()
  let len = chars.length()
  let mut idx = 0
  let mut start = 0
  for i = 0; i < len; i = i + 1 {
    if chars[i] == delimiter {
      if i > start {
        let buf = StringBuilder::new()
        for j = start; j < i; j = j + 1 {
          // Skip carriage return when not using read0
          if not(read0) && chars[j] == '\r' {
            continue
          }
          buf.write_char(chars[j])
        }
        let line = buf.to_string()
        if line.length() > 0 {
          items.push(@core.Item::new(line, idx))
          idx = idx + 1
        }
      }
      start = i + 1
    }
  }
  // Handle last line without delimiter
  if start < len {
    let buf = StringBuilder::new()
    for j = start; j < len; j = j + 1 {
      if not(read0) && chars[j] == '\r' {
        continue
      }
      buf.write_char(chars[j])
    }
    let line = buf.to_string()
    if line.length() > 0 {
      items.push(@core.Item::new(line, idx))
    }
  }
  items
}

///|
/// Parse history content string into lines array
pub fn parse_history_content(content : String) -> Array[String] {
  let history : Array[String] = []
  if content.length() == 0 {
    return history
  }
  let lines = @core.split_lines(content)
  for line in lines {
    if line.length() > 0 {
      history.push(line)
    }
  }
  history
}

///|
/// Build history output string (read existing, append new, truncate)
pub fn build_history_output(
  existing : Array[String],
  new_query : String,
  max_size : Int,
) -> String {
  // Append new query
  existing.push(new_query)
  // Truncate if exceeds max_size
  let start = if existing.length() > max_size {
    existing.length() - max_size
  } else {
    0
  }
  // Build output
  let buf = StringBuilder::new()
  for i = start; i < existing.length(); i = i + 1 {
    buf.write_string(existing[i])
    buf.write_string("\n")
  }
  buf.to_string()
}

///|
/// Result of extracting header lines from items
pub struct HeaderExtraction {
  items : Array[@core.Item]
  header : String
}

///|
/// Extract first N lines as header from items
pub fn extract_header_lines(
  items : Array[@core.Item],
  header_lines : Int,
) -> HeaderExtraction {
  if header_lines <= 0 {
    return { items, header: "" }
  }
  if items.length() <= header_lines {
    // All items become header, no items left
    let buf = StringBuilder::new()
    for i = 0; i < items.length(); i = i + 1 {
      if i > 0 {
        buf.write_string("\n")
      }
      buf.write_string(items[i].text)
    }
    return { items: [], header: buf.to_string() }
  }
  // Extract header lines and reindex remaining
  let header_items : Array[@core.Item] = []
  let remaining_items : Array[@core.Item] = []
  for i = 0; i < items.length(); i = i + 1 {
    if i < header_lines {
      header_items.push(items[i])
    } else {
      // Reindex remaining items
      remaining_items.push(@core.Item::new(items[i].text, i - header_lines))
    }
  }
  // Build header string
  let buf = StringBuilder::new()
  for i = 0; i < header_items.length(); i = i + 1 {
    if i > 0 {
      buf.write_string("\n")
    }
    buf.write_string(header_items[i].text)
  }
  { items: remaining_items, header: buf.to_string() }
}

///|
/// Combine headers from --header-lines and --header option
pub fn combine_headers(header_from_lines : String, header_option : String) -> String {
  if header_from_lines.length() > 0 && header_option.length() > 0 {
    header_from_lines + "\n" + header_option
  } else if header_from_lines.length() > 0 {
    header_from_lines
  } else {
    header_option
  }
}

///|
/// Filter items using the specified options (for --filter mode)
pub fn filter_items_batch(
  filter : String,
  items : Array[@core.Item],
  extended : Bool,
  exact : Bool,
  ignore_case : Bool,
  no_sort : Bool,
) -> Array[@core.MatchResult] {
  let case_sensitive = if ignore_case {
    false
  } else {
    @core.has_uppercase_query(filter)
  }
  if extended {
    if no_sort {
      @core.filter_extended_no_sort(filter, items, case_sensitive)
    } else {
      @core.filter_extended(filter, items, case_sensitive)
    }
  } else if exact {
    if no_sort {
      @core.filter_exact_no_sort(filter, items, ignore_case)
    } else {
      @core.filter_exact(filter, items, ignore_case)
    }
  } else if ignore_case {
    if no_sort {
      @core.filter_without_sort_ignore_case(filter, items)
    } else {
      @core.filter_and_score_ignore_case(filter, items)
    }
  } else if no_sort {
    @core.filter_without_sort(filter, items)
  } else {
    @core.filter_and_score(filter, items)
  }
}

///|
/// Output filtered results (for --filter mode)
pub fn output_filter_results(
  results : Array[@core.MatchResult],
  filter : String,
  print_query : Bool,
  print0 : Bool,
) -> Unit {
  // Output print_query first if requested
  if print_query {
    if print0 {
      @io.print_raw(filter)
      @io.print_raw("\u0000")
    } else {
      println(filter)
    }
  }
  // Output matching items
  for result in results {
    if print0 {
      @io.print_raw(result.item.text)
      @io.print_raw("\u0000")
    } else {
      println(result.item.text)
    }
  }
}
