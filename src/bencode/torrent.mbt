///|
/// Extracts the 'info' dictionary from a torrent BValue, serializes it,
/// and calculates its 20-byte SHA-1 hash (info_hash).
/// Returns None if the root value is not a dictionary or does not contain 'info'.
pub fn BValue::info_hash(self : BValue) -> Bytes? {
  match self {
    BDict(dict) => {
      let mut info_val = None
      for kv in dict {
        if kv.0 == b"info" {
          info_val = Some(kv.1)
          break
        }
      }
      match info_val {
        Some(val) => {
          let encoded = encode(val)
          Some(sha1(encoded))
        }
        None => None
      }
    }
    _ => None
  }
}

///|
/// Extracts the 'info' dictionary from a torrent BValueView, serializes it,
/// and calculates its 20-byte SHA-1 hash (info_hash).
/// Returns None if the root value is not a dictionary or does not contain 'info'.
pub fn BValueView::info_hash(self : BValueView) -> Bytes? {
  match self {
    BDict(dict) => {
      let mut info_val = None
      for kv in dict {
        if bytes_view_equals_bytes(kv.0, b"info") {
          info_val = Some(kv.1)
          break
        }
      }
      match info_val {
        Some(val) => {
          let encoded = encode_view(val)
          Some(sha1(encoded))
        }
        None => None
      }
    }
    _ => None
  }
}
