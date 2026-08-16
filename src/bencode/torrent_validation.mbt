///|
/// Small validation predicates suitable for UI indicators and CI assertions.
pub fn valid_torrent(value : BValue) -> Bool raise TorrentError {
  match TorrentMeta::from_bvalue(value) {
    _ => true
  }
}

///|
pub fn valid_torrent_with_policy(
  value : BValue,
  policy : TorrentPolicy,
) -> Bool raise TorrentError {
  policy.accepts(TorrentMeta::from_bvalue(value))
}

///|
pub fn valid_name(value : Bytes) -> Bool {
  value.length() > 0 && value != b"." && value != b".."
}

///|
pub fn valid_piece_blob(
  value : Bytes,
  total : Int64,
  piece_length : Int,
) -> Bool {
  is_piece_hash_blob(value) &&
  value.length() / 20 == expected_piece_count(total, piece_length)
}

///|
pub fn valid_file_list(files : Array[TorrentFile]) -> Bool {
  if files.length() == 0 {
    return false
  }
  for file in files {
    if !safe_file(file) {
      return false
    }
  }
  true
}

///|
pub fn valid_tracker_list(trackers : Array[Bytes]) -> Bool {
  tracker_list_supported(trackers)
}

///|
pub fn validation_summary(value : BValue) -> Bytes raise TorrentError {
  if valid_torrent(value) {
    b"valid"
  } else {
    b"invalid"
  }
}

///|
pub fn validation_score(meta : TorrentMeta) -> Int raise TorrentError {
  let assessment = TorrentPolicy::default().assess(meta)
  assessment.score()
}

///|
pub fn validation_is_production_ready(
  meta : TorrentMeta,
) -> Bool raise TorrentError {
  let assessment = TorrentPolicy::strict().assess(meta)
  assessment.is_accepted() && !assessment.has_warnings()
}

///|
pub fn validation_has_real_payload(meta : TorrentMeta) -> Bool {
  meta.total_length > 0L && meta.pieces.length() > 0
}

///|
pub fn validation_has_canonical_info(meta : TorrentMeta) -> Bool {
  encode(meta.info) == canonical_bytes(meta.info)
}

///|
pub fn validation_matches_piece_count(meta : TorrentMeta) -> Bool {
  meta.piece_count() == meta.pieces.length() / 20
}

///|
pub fn validation_is_reproducible(meta : TorrentMeta) -> Bool {
  meta.info_hash.length() == 20 && validation_matches_piece_count(meta)
}

///|
pub fn validation_has_tracker(meta : TorrentMeta) -> Bool {
  meta.announce.length() > 0
}

///|
pub fn validation_is_private(meta : TorrentMeta) -> Bool {
  meta.is_private
}

///|
pub fn validation_file_count(meta : TorrentMeta) -> Int {
  meta.files.length()
}

///|
pub fn validation_total_length(meta : TorrentMeta) -> Int64 {
  meta.total_length
}

///|
pub fn validation_piece_length(meta : TorrentMeta) -> Int {
  meta.piece_length
}

///|
pub fn validation_hash_length(meta : TorrentMeta) -> Int {
  meta.info_hash.length()
}

///|
pub fn validation_depth(meta : TorrentMeta) -> Int raise TorrentError {
  TorrentLayout::new(meta.files, meta.piece_length).max_depth()
}

///|
pub fn validation_directory_count(meta : TorrentMeta) -> Int raise TorrentError {
  TorrentLayout::new(meta.files, meta.piece_length).directory_count()
}

///|
pub fn validation_is_small(meta : TorrentMeta) -> Bool {
  meta.total_length < 1048576L
}
