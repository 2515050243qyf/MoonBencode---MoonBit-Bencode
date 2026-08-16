///|
/// A stable, serialization-friendly summary of validated metainfo.
pub(all) struct TorrentReport {
  name : Bytes
  file_count : Int
  total_length : Int64
  piece_length : Int
  piece_count : Int
  tracker_count : Int
  is_private : Bool
  is_multi_file : Bool
  max_depth : Int
  directory_count : Int
  info_hash : Bytes
} derive(Eq, Debug)

///|
pub fn TorrentReport::from_meta(
  meta : TorrentMeta,
) -> TorrentReport raise TorrentError {
  let layout = TorrentLayout::new(meta.files, meta.piece_length)
  {
    name: meta.name,
    file_count: layout.file_count(),
    total_length: meta.total_length,
    piece_length: meta.piece_length,
    piece_count: meta.piece_count(),
    tracker_count: meta.announce.length(),
    is_private: meta.is_private,
    is_multi_file: layout.is_multi_file(),
    max_depth: layout.max_depth(),
    directory_count: layout.directory_count(),
    info_hash: meta.info_hash,
  }
}

///|
pub fn TorrentReport::is_empty(self : TorrentReport) -> Bool {
  self.total_length == 0L
}

///|
pub fn TorrentReport::has_trackers(self : TorrentReport) -> Bool {
  self.tracker_count > 0
}

///|
pub fn TorrentReport::uses_small_pieces(self : TorrentReport) -> Bool {
  self.piece_length <= 65536
}

///|
pub fn TorrentReport::uses_large_pieces(self : TorrentReport) -> Bool {
  self.piece_length >= 1048576
}

///|
pub fn TorrentReport::average_piece_payload(self : TorrentReport) -> Int64 {
  if self.piece_count == 0 {
    0L
  } else {
    self.total_length / self.piece_count.to_int64()
  }
}

///|
pub fn TorrentReport::hash_is_sha1(self : TorrentReport) -> Bool {
  self.info_hash.length() == 20
}

///|
pub fn TorrentReport::file_density(self : TorrentReport) -> Int {
  if self.total_length == 0L {
    0
  } else {
    (self.file_count.to_int64() * 100L / self.total_length).to_int()
  }
}

///|
pub fn TorrentReport::piece_density(self : TorrentReport) -> Int {
  if self.total_length == 0L {
    0
  } else {
    (self.piece_count.to_int64() * 100L / self.total_length).to_int()
  }
}

///|
pub fn TorrentReport::has_nested_paths(self : TorrentReport) -> Bool {
  self.max_depth > 1
}

///|
pub fn TorrentReport::layout_kind(self : TorrentReport) -> Bytes {
  if self.is_multi_file {
    b"multi-file"
  } else {
    b"single-file"
  }
}

///|
pub fn TorrentReport::piece_span_count(
  _self : TorrentReport,
  layout : TorrentLayout,
) -> Int {
  layout.total_piece_spans()
}

///|
pub fn TorrentReport::same_content(
  self : TorrentReport,
  other : TorrentReport,
) -> Bool {
  self.info_hash == other.info_hash
}
