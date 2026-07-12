///|
/// BValue is the abstract syntax tree (AST) representation of a Bencode value.
/// Bencode supports four basic data types: integers, byte strings, lists, and dictionaries.
pub(all) enum BValue {
  /// Represents a Bencode integer. Backed by a 64-bit signed integer.
  BInt(Int64)
  /// Represents a Bencode string. Bencode strings are byte strings and may not be valid UTF-8.
  BStr(Bytes)
  /// Represents a Bencode list, which can contain any other Bencode values.
  BList(Array[BValue])
  /// Represents a Bencode dictionary. Keys are strictly byte strings to ensure hash fidelity.
  BDict(Array[(Bytes, BValue)])
} derive(Eq, Debug)

///|
pub impl Show for BValue with fn output(_self, logger) {
  logger.write_string("BValue")
}

///|
/// DecodeError represents all possible errors that can occur during Bencode deserialization.
pub suberror DecodeError {
  /// Thrown when the bencode byte stream does not conform to the specification.
  InvalidFormat(String)
  /// Thrown when the byte stream ends unexpectedly while parsing a value.
  UnexpectedEOF
} derive(Eq, Debug)

///|
/// BValueView is a zero-copy AST representation of a Bencode value using BytesView.
pub(all) enum BValueView {
  BInt(Int64)
  BStr(BytesView)
  BList(Array[BValueView])
  BDict(Array[(BytesView, BValueView)])
} derive(Eq, Debug)

///|
pub impl Show for BValueView with fn output(_self, logger) {
  logger.write_string("BValueView")
}

///|
/// Converts a BValueView into an owned BValue by copying the underlying byte slices.
pub fn BValueView::to_bvalue(self : BValueView) -> BValue {
  match self {
    BInt(i) => BInt(i)
    BStr(view) => BStr(view.to_owned())
    BList(list) => BList(list.map(fn(v) { v.to_bvalue() }))
    BDict(dict) =>
      BDict(dict.map(fn(kv) { (kv.0.to_owned(), kv.1.to_bvalue()) }))
  }
}
