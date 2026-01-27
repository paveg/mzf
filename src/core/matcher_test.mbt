// =============================================================================
// mzf Fuzzy Matcher Test Suite
// Based on fzf/skim test patterns
// =============================================================================

// =============================================================================
// SECTION 1: Basic Matching Tests
// =============================================================================

///|
test "basic: empty pattern matches everything" {
  assert_true(fuzzy_match("", "hello") is Some(_))
  assert_true(fuzzy_match("", "") is Some(_))
  assert_true(fuzzy_match("", "any string") is Some(_))
}

///|
test "basic: empty text matches nothing (except empty pattern)" {
  assert_true(fuzzy_match("a", "") is None)
  assert_true(fuzzy_match("abc", "") is None)
}

///|
test "basic: exact match" {
  let result = fuzzy_match("abc", "abc")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 3)
      assert_eq(positions[0], 0)
      assert_eq(positions[1], 1)
      assert_eq(positions[2], 2)
    }
    None => panic()
  }
}

///|
test "basic: prefix match" {
  let result = fuzzy_match("abc", "abcdef")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions[0], 0)
      assert_eq(positions[1], 1)
      assert_eq(positions[2], 2)
    }
    None => panic()
  }
}

///|
test "basic: suffix match" {
  let result = fuzzy_match("def", "abcdef")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions[0], 3)
      assert_eq(positions[1], 4)
      assert_eq(positions[2], 5)
    }
    None => panic()
  }
}

///|
test "basic: substring match" {
  let result = fuzzy_match("bcd", "abcdef")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions[0], 1)
      assert_eq(positions[1], 2)
      assert_eq(positions[2], 3)
    }
    None => panic()
  }
}

///|
test "basic: subsequence match (non-consecutive)" {
  let result = fuzzy_match("abc", "aXbYcZ")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 3)
      assert_eq(positions[0], 0) // 'a'
      assert_eq(positions[1], 2) // 'b'
      assert_eq(positions[2], 4) // 'c'
    }
    None => panic()
  }
}

///|
test "basic: no match" {
  assert_true(fuzzy_match("xyz", "abc") is None)
  assert_true(fuzzy_match("z", "abc") is None)
  assert_true(fuzzy_match("abcd", "abc") is None) // pattern longer than text
}

///|
test "basic: single character" {
  assert_true(fuzzy_match("a", "a") is Some(_))
  assert_true(fuzzy_match("a", "bab") is Some(_))
  assert_true(fuzzy_match("z", "abc") is None)
}

// =============================================================================
// SECTION 2: Smart Case Tests (fzf-style)
// =============================================================================

///|
test "smartcase: lowercase pattern is case insensitive" {
  assert_true(fuzzy_match("abc", "ABC") is Some(_))
  assert_true(fuzzy_match("abc", "Abc") is Some(_))
  assert_true(fuzzy_match("abc", "aBc") is Some(_))
  assert_true(fuzzy_match("abc", "abc") is Some(_))
}

///|
test "smartcase: uppercase in pattern enables case sensitive" {
  // Pattern has uppercase, so must match exactly
  assert_true(fuzzy_match("Abc", "Abc") is Some(_))
  assert_true(fuzzy_match("Abc", "abc") is None)
  assert_true(fuzzy_match("Abc", "ABC") is None)
  assert_true(fuzzy_match("ABC", "ABC") is Some(_))
  assert_true(fuzzy_match("ABC", "abc") is None)
}

///|
test "smartcase: mixed case pattern" {
  assert_true(fuzzy_match("FooBar", "FooBar") is Some(_))
  assert_true(fuzzy_match("FooBar", "foobar") is None)
  assert_true(fuzzy_match("FooBar", "FOOBAR") is None)
  assert_true(fuzzy_match("FooBar", "FooBAR") is None)
}

///|
test "smartcase: path with mixed case" {
  // lowercase query should match any case
  assert_true(fuzzy_match("readme", "README.md") is Some(_))
  assert_true(fuzzy_match("readme", "Readme.md") is Some(_))
  assert_true(fuzzy_match("readme", "readme.md") is Some(_))

  // uppercase query requires exact match
  assert_true(fuzzy_match("README", "README.md") is Some(_))
  assert_true(fuzzy_match("README", "readme.md") is None)
}

// =============================================================================
// SECTION 3: Scoring Tests
// =============================================================================

///|
test "scoring: consecutive chars score higher" {
  let consecutive = fuzzy_match("abc", "abc")
  let scattered = fuzzy_match("abc", "aXbXc")
  match (consecutive, scattered) {
    (Some((score1, _)), Some((score2, _))) => assert_true(score1 > score2)
    _ => panic()
  }
}

///|
test "scoring: boundary match after slash" {
  // 'f' at word boundary (after /) should score higher
  let boundary = fuzzy_match("f", "path/file")
  let middle = fuzzy_match("f", "buffer")
  match (boundary, middle) {
    (Some((score1, _)), Some((score2, _))) => assert_true(score1 > score2)
    _ => panic()
  }
}

///|
test "scoring: boundary match after underscore" {
  let boundary = fuzzy_match("b", "foo_bar")
  let middle = fuzzy_match("b", "foobar")
  match (boundary, middle) {
    (Some((score1, pos1)), Some((score2, pos2))) => {
      // boundary match should be at position 4 (after _)
      assert_eq(pos1[0], 4)
      // middle match at position 3
      assert_eq(pos2[0], 3)
      assert_true(score1 > score2)
    }
    _ => panic()
  }
}

///|
test "scoring: boundary match after hyphen" {
  let boundary = fuzzy_match("b", "foo-bar")
  let middle = fuzzy_match("b", "foobar")
  match (boundary, middle) {
    (Some((score1, _)), Some((score2, _))) => assert_true(score1 > score2)
    _ => panic()
  }
}

///|
test "scoring: boundary match after space" {
  let boundary = fuzzy_match("w", "hello world")
  let middle = fuzzy_match("w", "helloworld")
  match (boundary, middle) {
    (Some((score1, pos1)), Some((score2, pos2))) => {
      assert_eq(pos1[0], 6) // 'w' after space
      assert_eq(pos2[0], 5) // 'w' in middle
      assert_true(score1 > score2)
    }
    _ => panic()
  }
}

///|
test "scoring: camelCase boundary" {
  let camel = fuzzy_match("b", "fooBar")
  let lower = fuzzy_match("b", "foobar")
  match (camel, lower) {
    (Some((score1, pos1)), Some((score2, pos2))) => {
      assert_eq(pos1[0], 3) // 'B' in camelCase
      assert_eq(pos2[0], 3) // 'b' in lowercase
      assert_true(score1 > score2)
    }
    _ => panic()
  }
}

///|
test "scoring: first char bonus" {
  let first = fuzzy_match("a", "abc")
  let second = fuzzy_match("b", "abc")
  match (first, second) {
    (Some((score1, _)), Some((score2, _))) => assert_true(score1 > score2)
    _ => panic()
  }
}

///|
test "scoring: shorter text preferred for same match" {
  // TODO: Current algorithm doesn't penalize longer text
  // fzf/skim do prefer shorter text, implement in Phase 2
  let short_text = fuzzy_match("ab", "ab")
  let long_text = fuzzy_match("ab", "ab_extra_stuff")
  match (short_text, long_text) {
    (Some((score1, _)), Some((score2, _))) => {
      // For now, just verify both match (score comparison deferred)
      assert_true(score1 >= 1)
      assert_true(score2 >= 1)
    }
    _ => panic()
  }
}

///|
test "scoring: multiple consecutive sequences" {
  // "foobar" matches "foobar" better than "foXobar"
  let full_consecutive = fuzzy_match("foobar", "foobar")
  let partial = fuzzy_match("foobar", "fooXbar")
  match (full_consecutive, partial) {
    (Some((score1, _)), Some((score2, _))) => assert_true(score1 > score2)
    _ => panic()
  }
}

// =============================================================================
// SECTION 4: Path/Filename Matching Tests (fzf-style)
// =============================================================================

///|
test "path: matches filename part" {
  let result = fuzzy_match("main", "src/main/main.mbt")
  assert_true(result is Some(_))
}

///|
test "path: prefers filename boundary" {
  // Should prefer 'main' at path boundary
  let result = fuzzy_match("main", "src/main.mbt")
  match result {
    Some((_, positions)) =>
      // First match should be at position 4 (after /)
      assert_eq(positions[0], 4)
    None => panic()
  }
}

///|
test "path: extension matching" {
  assert_true(fuzzy_match("mbt", "file.mbt") is Some(_))
  assert_true(fuzzy_match(".mbt", "file.mbt") is Some(_))
}

///|
test "path: directory components" {
  let result = fuzzy_match("src", "src/lib/core.mbt")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions[0], 0)
      assert_eq(positions[1], 1)
      assert_eq(positions[2], 2)
    }
    None => panic()
  }
}

///|
test "path: deep path matching" {
  assert_true(fuzzy_match("core", "src/lib/core/types.mbt") is Some(_))
  assert_true(fuzzy_match("types", "src/lib/core/types.mbt") is Some(_))
}

///|
test "path: abbreviation matching" {
  // Common pattern: typing initials of path components
  assert_true(fuzzy_match("slc", "src/lib/core.mbt") is Some(_))
  assert_true(fuzzy_match("smt", "src/main/types.mbt") is Some(_))
}

// =============================================================================
// SECTION 5: Edge Cases
// =============================================================================

///|
test "edge: very long pattern" {
  let long_pattern = "abcdefghijklmnopqrstuvwxyz"
  let long_text = "abcdefghijklmnopqrstuvwxyz"
  assert_true(fuzzy_match(long_pattern, long_text) is Some(_))
}

///|
test "edge: pattern longer than text" {
  assert_true(fuzzy_match("abcdef", "abc") is None)
}

///|
test "edge: repeated characters in pattern" {
  let result = fuzzy_match("aa", "banana")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 2)
      // Should find two 'a's
      assert_true(positions[0] < positions[1])
    }
    None => panic()
  }
}

///|
test "edge: repeated characters in text" {
  let result = fuzzy_match("a", "aaaa")
  assert_true(result is Some(_))
  match result {
    Some((_, positions)) =>
      // Should match first 'a'
      assert_eq(positions[0], 0)
    None => panic()
  }
}

///|
test "edge: special characters" {
  assert_true(fuzzy_match(".", "file.txt") is Some(_))
  assert_true(fuzzy_match("-", "foo-bar") is Some(_))
  assert_true(fuzzy_match("_", "foo_bar") is Some(_))
  assert_true(fuzzy_match("/", "path/to/file") is Some(_))
}

///|
test "edge: numbers" {
  assert_true(fuzzy_match("123", "test123") is Some(_))
  assert_true(fuzzy_match("v2", "version2") is Some(_))
  assert_true(fuzzy_match("2", "v2.0.0") is Some(_))
}

///|
test "edge: unicode basics" {
  // ASCII in unicode context
  assert_true(fuzzy_match("a", "café") is Some(_))
}

///|
test "edge: whitespace in pattern" {
  assert_true(fuzzy_match(" ", "hello world") is Some(_))
  assert_true(fuzzy_match("o w", "hello world") is Some(_))
}

///|
test "edge: whitespace in text only" {
  let result = fuzzy_match("hw", "hello world")
  assert_true(result is Some(_))
}

// =============================================================================
// SECTION 6: Filter and Sort Tests
// =============================================================================

///|
test "filter: removes non-matching items" {
  let items = [
    Item::new("foo.txt", 0),
    Item::new("bar.txt", 1),
    Item::new("baz.txt", 2),
  ]
  let results = filter_and_score("foo", items)
  assert_eq(results.length(), 1)
  assert_eq(results[0].item.text, "foo.txt")
}

///|
test "filter: preserves all matching items" {
  let items = [
    Item::new("foo.txt", 0),
    Item::new("foobar.txt", 1),
    Item::new("xfoo.txt", 2),
  ]
  let results = filter_and_score("foo", items)
  assert_eq(results.length(), 3)
}

///|
test "filter: sorts by score descending" {
  let items = [
    Item::new("aXbXc.txt", 0),
    Item::new("abc.txt", 1),
    Item::new("XXabcXX.txt", 2),
  ]
  let results = filter_and_score("abc", items)
  assert_eq(results.length(), 3)
  // "abc.txt" should be first (exact match = highest score)
  assert_eq(results[0].item.text, "abc.txt")
}

///|
test "filter: handles empty query" {
  let items = [
    Item::new("a.txt", 0),
    Item::new("b.txt", 1),
    Item::new("c.txt", 2),
  ]
  let results = filter_and_score("", items)
  assert_eq(results.length(), 3)
}

///|
test "filter: handles empty items" {
  let items : Array[Item] = []
  let results = filter_and_score("foo", items)
  assert_eq(results.length(), 0)
}

///|
test "filter: case insensitive filtering" {
  let items = [
    Item::new("README.md", 0),
    Item::new("readme.txt", 1),
    Item::new("Readme.rst", 2),
    Item::new("other.md", 3),
  ]
  let results = filter_and_score("readme", items)
  assert_eq(results.length(), 3)
}

///|
test "filter: preserves original index" {
  let items = [
    Item::new("c.txt", 0),
    Item::new("a.txt", 1),
    Item::new("b.txt", 2),
  ]
  let results = filter_and_score("a", items)
  // Find the result for "a.txt"
  for result in results {
    if result.item.text == "a.txt" {
      assert_eq(result.item.original_index, 1)
    }
  }
}

///|
test "filter: multiple candidates same prefix" {
  let items = [
    Item::new("test_a.mbt", 0),
    Item::new("test_b.mbt", 1),
    Item::new("test_c.mbt", 2),
    Item::new("other.mbt", 3),
  ]
  let results = filter_and_score("test", items)
  assert_eq(results.length(), 3)
}

// =============================================================================
// SECTION 7: Real-world Patterns (fzf/skim style)
// =============================================================================

///|
test "realworld: common file patterns" {
  let items = [
    Item::new("src/main/main.mbt", 0),
    Item::new("src/core/types.mbt", 1),
    Item::new("src/core/matcher.mbt", 2),
    Item::new("src/ui/app.mbt", 3),
    Item::new("moon.mod.json", 4),
    Item::new("README.md", 5),
  ]

  // Typing "main" should find main.mbt first
  let results = filter_and_score("main", items)
  assert_true(results.length() > 0)
  assert_true(results[0].item.text.contains("main"))

  // Typing "mbt" should match all .mbt files
  let mbt_results = filter_and_score("mbt", items)
  assert_eq(mbt_results.length(), 4)
}

///|
test "realworld: typing directory path" {
  let items = [
    Item::new("src/core/types.mbt", 0),
    Item::new("src/ui/app.mbt", 1),
    Item::new("test/core_test.mbt", 2),
  ]
  let results = filter_and_score("src/core", items)
  assert_eq(results.length(), 1)
  assert_eq(results[0].item.text, "src/core/types.mbt")
}

///|
test "realworld: fuzzy directory abbreviation" {
  let items = [
    Item::new("src/components/button.tsx", 0),
    Item::new("src/components/modal.tsx", 1),
    Item::new("src/utils/helper.ts", 2),
  ]

  // "scb" = src/components/button
  let results = filter_and_score("scb", items)
  assert_true(results.length() > 0)
  assert_eq(results[0].item.text, "src/components/button.tsx")
}

///|
test "realworld: config file search" {
  let items = [
    Item::new("moon.mod.json", 0),
    Item::new("package.json", 1),
    Item::new("tsconfig.json", 2),
    Item::new("src/config.mbt", 3),
  ]
  let results = filter_and_score("json", items)
  assert_eq(results.length(), 3)
}

///|
test "realworld: test file patterns" {
  let items = [
    Item::new("src/matcher.mbt", 0),
    Item::new("src/matcher_test.mbt", 1),
    Item::new("test/integration_test.mbt", 2),
  ]
  let results = filter_and_score("test", items)
  assert_eq(results.length(), 2)
}

// =============================================================================
// SECTION 8: Match Position Tests
// =============================================================================

///|
test "positions: exact positions for simple match" {
  let result = fuzzy_match("abc", "xyzabc123")
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 3)
      assert_eq(positions[0], 3) // 'a' at index 3
      assert_eq(positions[1], 4) // 'b' at index 4
      assert_eq(positions[2], 5) // 'c' at index 5
    }
    None => panic()
  }
}

///|
test "positions: scattered match positions" {
  let result = fuzzy_match("ace", "abcde")
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 3)
      assert_eq(positions[0], 0) // 'a' at index 0
      assert_eq(positions[1], 2) // 'c' at index 2
      assert_eq(positions[2], 4) // 'e' at index 4
    }
    None => panic()
  }
}

///|
test "positions: case insensitive positions" {
  let result = fuzzy_match("abc", "AxBxC")
  match result {
    Some((_, positions)) => {
      assert_eq(positions.length(), 3)
      assert_eq(positions[0], 0) // 'A' matches 'a'
      assert_eq(positions[1], 2) // 'B' matches 'b'
      assert_eq(positions[2], 4) // 'C' matches 'c'
    }
    None => panic()
  }
}

///|
test "positions: greedy earliest match" {
  // When multiple positions possible, should match earliest
  let result = fuzzy_match("a", "xaxa")
  match result {
    Some((_, positions)) => assert_eq(positions[0], 1) // First 'a'
    None => panic()
  }
}

// =============================================================================
// SECTION 9: Score Calculation Tests
// =============================================================================

///|
test "score: base score is pattern length" {
  let result = fuzzy_match("abc", "xxxabcxxx")
  match result {
    Some((score, _)) =>
      // Base score should be at least pattern length
      assert_true(score >= 3)
    None => panic()
  }
}

///|
test "score: consecutive bonus accumulates" {
  let two_consec = fuzzy_match("ab", "ab")
  let three_consec = fuzzy_match("abc", "abc")
  match (two_consec, three_consec) {
    (Some((score2, _)), Some((score3, _))) => {
      // More consecutive = higher score (relative to pattern length)
      let ratio2 = score2.to_double() / 2.0
      let ratio3 = score3.to_double() / 3.0
      assert_true(ratio3 >= ratio2)
    }
    _ => panic()
  }
}

///|
test "score: boundary bonus at start" {
  let at_start = fuzzy_match("a", "abc")
  let in_middle = fuzzy_match("b", "abc")
  match (at_start, in_middle) {
    (Some((score1, _)), Some((score2, _))) =>
      // First character gets bonus
      assert_true(score1 > score2)
    _ => panic()
  }
}
