///|
/// Item represents a single candidate line from stdin
pub struct Item {
  text : String
  original_index : Int
} derive(Show, Eq)

///|
/// MatchResult represents a matched item with score and match positions
pub struct MatchResult {
  item : Item
  score : Int
  match_positions : Array[Int]
} derive(Show, Eq)

///|
pub fn Item::new(text : String, original_index : Int) -> Item {
  { text, original_index }
}

///|
pub fn MatchResult::new(
  item : Item,
  score : Int,
  match_positions : Array[Int]
) -> MatchResult {
  { item, score, match_positions }
}
