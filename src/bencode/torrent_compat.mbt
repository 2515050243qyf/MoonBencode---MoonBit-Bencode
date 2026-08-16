///|
/// Compatibility helpers for common BitTorrent metainfo conventions.
pub fn is_v1_info_hash(value : Bytes) -> Bool {
  value.length() == 20
}

///|
pub fn is_piece_hash_blob(value : Bytes) -> Bool {
  value.length() % 20 == 0
}

///|
pub fn piece_hashes(value : Bytes) -> Array[Bytes] {
  let result : Array[Bytes] = []
  let mut index = 0
  while index + 20 <= value.length() {
    result.push(value.view(start=index, end=index + 20).to_owned())
    index += 20
  }
  result
}

///|
pub fn compat_piece_hash_at(value : Bytes, index : Int) -> Bytes? {
  if index < 0 || (index + 1) * 20 > value.length() {
    None
  } else {
    Some(value.view(start=index * 20, end=(index + 1) * 20).to_owned())
  }
}

///|
pub fn piece_hash_index(value : Bytes, needle : Bytes) -> Int? {
  for index = 0; index < value.length() / 20; index = index + 1 {
    if compat_piece_hash_at(value, index) == Some(needle) {
      return Some(index)
    }
  }
  None
}

///|
pub fn compat_piece_hash_count(value : Bytes) -> Int {
  value.length() / 20
}

///|
pub fn expected_piece_count(total : Int64, piece_length : Int) -> Int {
  if total <= 0L || piece_length <= 0 {
    0
  } else {
    ((total + piece_length.to_int64() - 1L) / piece_length.to_int64()).to_int()
  }
}

///|
pub fn piece_blob_length(piece_count : Int) -> Int {
  if piece_count <= 0 {
    0
  } else {
    piece_count * 20
  }
}

///|
pub fn piece_length_is_standard(value : Int) -> Bool {
  value >= 16384 && value <= 16777216 && value % 16384 == 0
}

///|
pub fn file_length_is_valid(value : Int64) -> Bool {
  value >= 0L
}

///|
pub fn tracker_is_http(value : Bytes) -> Bool {
  (value.length() >= 7 && value.view(start=0, end=7).to_owned() == b"http://") ||
  (value.length() >= 8 && value.view(start=0, end=8).to_owned() == b"https://")
}

///|
pub fn tracker_is_udp(value : Bytes) -> Bool {
  value.length() >= 6 && value.view(start=0, end=6).to_owned() == b"udp://"
}

///|
pub fn tracker_is_supported(value : Bytes) -> Bool {
  tracker_is_http(value) || tracker_is_udp(value)
}

///|
pub fn tracker_scheme(value : Bytes) -> Bytes {
  if tracker_is_http(value) {
    b"http"
  } else if tracker_is_udp(value) {
    b"udp"
  } else {
    b"unknown"
  }
}

///|
pub fn tracker_list_supported(values : Array[Bytes]) -> Bool {
  for value in values {
    if !tracker_is_supported(value) {
      return false
    }
  }
  true
}

///|
pub fn info_dictionary_hash(value : BValue) -> Bytes? {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(info) => Some(sha1(encode(info)))
        None => None
      }
    _ => None
  }
}

///|
pub fn info_dictionary_bytes(value : BValue) -> Bytes? {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(info) => Some(encode(info))
        None => None
      }
    _ => None
  }
}

///|
pub fn metainfo_is_round_trippable(value : BValue) -> Bool raise DecodeError {
  match decode(encode(value)) {
    result => result == value
  }
}

///|
pub fn metainfo_is_canonical(value : BValue) -> Bool {
  encode(value) == canonical_bytes(value)
}

///|
pub fn metainfo_size(value : BValue) -> Int {
  encode(value).length()
}

///|
pub fn metainfo_profile(value : BValue) -> BValueProfile {
  profile(value)
}

///|
pub fn metainfo_layout(value : BValue) -> TorrentLayout? raise TorrentError {
  let meta = TorrentMeta::from_bvalue(value)
  Some(TorrentLayout::new(meta.files, meta.piece_length))
}

///|
pub fn metainfo_has_private_flag(value : BValue) -> Bool {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(BDict(info)) => dict_lookup(info, b"private") is Some(_)
        _ => false
      }
    _ => false
  }
}

///|
pub fn metainfo_name(value : BValue) -> Bytes? {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(BDict(info)) => field_bytes(BDict(info), b"name")
        _ => None
      }
    _ => None
  }
}

///|
pub fn metainfo_piece_length(value : BValue) -> Int64? {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(BDict(info)) => field_int(BDict(info), b"piece length")
        _ => None
      }
    _ => None
  }
}

///|
pub fn metainfo_is_single_file(value : BValue) -> Bool raise TorrentError {
  TorrentMeta::from_bvalue(value).files.length() == 1
}

///|
pub fn metainfo_is_multi_file(value : BValue) -> Bool raise TorrentError {
  TorrentMeta::from_bvalue(value).files.length() > 1
}
