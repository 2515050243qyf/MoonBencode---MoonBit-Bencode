///|
/// Result of validating piece payloads against the hashes in metainfo.
pub(all) struct PieceCheck {
  piece_index : Int
  expected : Bytes
  actual : Bytes
  matches : Bool
  payload_length : Int
} derive(Eq, Debug)

///|
pub fn PieceCheck::ok(self : PieceCheck) -> Bool {
  self.matches
}

///|
pub fn PieceCheck::is_empty(self : PieceCheck) -> Bool {
  self.payload_length == 0
}

///|
pub fn PieceCheck::expected_hash(self : PieceCheck) -> Bytes {
  self.expected
}

///|
pub fn PieceCheck::actual_hash(self : PieceCheck) -> Bytes {
  self.actual
}

///|
pub fn PieceCheck::index(self : PieceCheck) -> Int {
  self.piece_index
}

///|
pub fn PieceCheck::payload_size(self : PieceCheck) -> Int {
  self.payload_length
}

///|
fn piece_hash_at(pieces : Bytes, index : Int) -> Bytes? {
  let start = index * 20
  if index < 0 || start + 20 > pieces.length() {
    None
  } else {
    Some(pieces.view(start~, end=start + 20).to_owned())
  }
}

///|
pub fn verify_piece(
  meta : TorrentMeta,
  index : Int,
  payload : Bytes,
) -> PieceCheck raise TorrentError {
  match piece_hash_at(meta.pieces, index) {
    Some(expected) => {
      let actual = sha1(payload)
      {
        piece_index: index,
        expected,
        actual,
        matches: expected == actual,
        payload_length: payload.length(),
      }
    }
    None => raise InvalidMetadata("piece index is outside the torrent")
  }
}

///|
pub fn verify_all_pieces(
  meta : TorrentMeta,
  payloads : Array[Bytes],
) -> Array[PieceCheck] raise TorrentError {
  let result : Array[PieceCheck] = []
  for i = 0; i < payloads.length(); i = i + 1 {
    result.push(verify_piece(meta, i, payloads[i]))
  }
  result
}

///|
pub fn piece_hash(meta : TorrentMeta, index : Int) -> Bytes? {
  piece_hash_at(meta.pieces, index)
}

///|
pub fn piece_hash_count(meta : TorrentMeta) -> Int {
  meta.pieces.length() / 20
}

///|
pub fn matching_piece_count(checks : Array[PieceCheck]) -> Int {
  let mut result = 0
  for check in checks {
    if check.matches {
      result += 1
    }
  }
  result
}

///|
pub fn mismatching_piece_count(checks : Array[PieceCheck]) -> Int {
  checks.length() - matching_piece_count(checks)
}

///|
pub fn all_pieces_match(checks : Array[PieceCheck]) -> Bool {
  mismatching_piece_count(checks) == 0
}

///|
pub fn first_mismatch(checks : Array[PieceCheck]) -> PieceCheck? {
  for check in checks {
    if !check.matches {
      return Some(check)
    }
  }
  None
}

///|
pub fn total_checked_bytes(checks : Array[PieceCheck]) -> Int64 {
  let mut result = 0L
  for check in checks {
    result += check.payload_length.to_int64()
  }
  result
}

///|
pub fn checks_for_file(
  layout : TorrentLayout,
  file_index : Int,
  checks : Array[PieceCheck],
) -> Array[PieceCheck] {
  let pieces = layout.pieces_for_file(file_index)
  let result : Array[PieceCheck] = []
  for check in checks {
    for piece in pieces {
      if check.piece_index == piece {
        result.push(check)
      }
    }
  }
  result
}
