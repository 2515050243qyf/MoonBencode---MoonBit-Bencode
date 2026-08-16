///|
/// Query helpers for applications that inspect torrent collections.
pub(all) struct TorrentQuery {
  meta : TorrentMeta
  layout : TorrentLayout
} derive(Debug)

///|
pub fn TorrentQuery::new(meta : TorrentMeta) -> TorrentQuery raise TorrentError {
  { meta, layout: TorrentLayout::new(meta.files, meta.piece_length) }
}

///|
pub fn TorrentQuery::meta(self : TorrentQuery) -> TorrentMeta {
  self.meta
}

///|
pub fn TorrentQuery::layout(self : TorrentQuery) -> TorrentLayout {
  self.layout
}

///|
pub fn TorrentQuery::file(self : TorrentQuery, index : Int) -> TorrentFile? {
  if index < 0 || index >= self.layout.file_count() {
    None
  } else {
    Some(self.layout.files()[index])
  }
}

///|
pub fn TorrentQuery::files(self : TorrentQuery) -> Array[TorrentFile] {
  self.layout.files()
}

///|
pub fn TorrentQuery::files_with_length_at_least(
  self : TorrentQuery,
  minimum : Int64,
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  for file in self.layout.files() {
    if file.length >= minimum {
      result.push(file)
    }
  }
  result
}

///|
pub fn TorrentQuery::files_with_length_at_most(
  self : TorrentQuery,
  maximum : Int64,
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  for file in self.layout.files() {
    if file.length <= maximum {
      result.push(file)
    }
  }
  result
}

///|
pub fn TorrentQuery::empty_files(self : TorrentQuery) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  for file in self.layout.files() {
    if file.length == 0L {
      result.push(file)
    }
  }
  result
}

///|
fn query_suffix(value : Bytes, suffix : Bytes) -> Bool {
  if suffix.length() > value.length() {
    return false
  }
  let start = value.length() - suffix.length()
  for i = 0; i < suffix.length(); i = i + 1 {
    if value[start + i] != suffix[i] {
      return false
    }
  }
  true
}

///|
pub fn TorrentQuery::files_with_extension(
  self : TorrentQuery,
  extension : Bytes,
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  let suffix = Bytes::add(b".", extension)
  for file in self.layout.files() {
    if query_suffix(file.leaf(), suffix) {
      result.push(file)
    }
  }
  result
}

///|
pub fn TorrentQuery::files_named(
  self : TorrentQuery,
  name : Bytes,
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  for file in self.layout.files() {
    if file.leaf() == name {
      result.push(file)
    }
  }
  result
}

///|
pub fn TorrentQuery::files_under(
  self : TorrentQuery,
  prefix : Array[Bytes],
) -> Array[TorrentFile] {
  self.layout.files_under(prefix)
}

///|
pub fn TorrentQuery::files_in_piece(
  self : TorrentQuery,
  piece : Int,
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  let seen : Array[Int] = []
  for span in self.layout.spans_for_piece(piece) {
    let mut exists = false
    for index in seen {
      if index == span.file_index {
        exists = true
      }
    }
    if !exists {
      seen.push(span.file_index)
      result.push(self.layout.files()[span.file_index])
    }
  }
  result
}

///|
pub fn TorrentQuery::piece_for_offset(
  self : TorrentQuery,
  offset : Int64,
) -> Int? {
  match self.layout.file_index_at(offset) {
    Some(_) => Some((offset / self.layout.piece_size().to_int64()).to_int())
    None => None
  }
}

///|
pub fn TorrentQuery::pieces_touching_file(
  self : TorrentQuery,
  index : Int,
) -> Array[Int] {
  self.layout.pieces_for_file(index)
}

///|
pub fn TorrentQuery::pieces_in_range(
  self : TorrentQuery,
  start : Int64,
  length : Int64,
) -> Array[Int] {
  let result : Array[Int] = []
  if length <= 0L || start < 0L || start >= self.layout.total_length {
    return result
  }
  let end = if start + length > self.layout.total_length {
    self.layout.total_length
  } else {
    start + length
  }
  let first = (start / self.layout.piece_size().to_int64()).to_int()
  let last = ((end - 1L) / self.layout.piece_size().to_int64()).to_int()
  for piece = first; piece <= last; piece = piece + 1 {
    result.push(piece)
  }
  result
}

///|
pub fn TorrentQuery::directory_files(
  self : TorrentQuery,
  directory : Array[Bytes],
) -> Array[TorrentFile] {
  self.layout.files_under(directory)
}

///|
pub fn TorrentQuery::directory_size(
  self : TorrentQuery,
  directory : Array[Bytes],
) -> Int64 {
  let mut total = 0L
  for file in self.directory_files(directory) {
    total += file.length
  }
  total
}

///|
pub fn TorrentQuery::directory_count(self : TorrentQuery) -> Int {
  self.layout.directory_count()
}

///|
pub fn TorrentQuery::depth(self : TorrentQuery) -> Int {
  self.layout.max_depth()
}

///|
pub fn TorrentQuery::largest(self : TorrentQuery) -> TorrentFile? {
  self.layout.largest_file()
}

///|
pub fn TorrentQuery::smallest(self : TorrentQuery) -> TorrentFile? {
  self.layout.smallest_file()
}

///|
pub fn TorrentQuery::total_size(self : TorrentQuery) -> Int64 {
  self.layout.total_length
}

///|
pub fn TorrentQuery::file_count(self : TorrentQuery) -> Int {
  self.layout.file_count()
}

///|
pub fn TorrentQuery::piece_count(self : TorrentQuery) -> Int {
  self.layout.piece_count()
}

///|
pub fn TorrentQuery::tracker_count(self : TorrentQuery) -> Int {
  self.meta.announce.length()
}

///|
pub fn TorrentQuery::trackers(self : TorrentQuery) -> Array[Bytes] {
  self.meta.announce.copy()
}

///|
pub fn TorrentQuery::has_tracker(self : TorrentQuery, tracker : Bytes) -> Bool {
  self.meta.has_tracker(tracker)
}

///|
pub fn TorrentQuery::private(self : TorrentQuery) -> Bool {
  self.meta.is_private
}

///|
pub fn TorrentQuery::single_file(self : TorrentQuery) -> Bool {
  self.layout.is_single_file()
}

///|
pub fn TorrentQuery::multi_file(self : TorrentQuery) -> Bool {
  self.layout.is_multi_file()
}

///|
pub fn TorrentQuery::extension_count(
  self : TorrentQuery,
  extension : Bytes,
) -> Int {
  self.files_with_extension(extension).length()
}

///|
pub fn TorrentQuery::zero_length_count(self : TorrentQuery) -> Int {
  self.empty_files().length()
}

///|
pub fn TorrentQuery::piece_utilization(self : TorrentQuery, piece : Int) -> Int {
  self.layout.piece_utilization(piece)
}

///|
pub fn TorrentQuery::piece_spans(
  self : TorrentQuery,
  piece : Int,
) -> Array[PieceSpan] {
  self.layout.spans_for_piece(piece)
}

///|
pub fn TorrentQuery::path_exists(
  self : TorrentQuery,
  path : Array[Bytes],
) -> Bool {
  self.layout.contains(path)
}

///|
pub fn TorrentQuery::path_size(
  self : TorrentQuery,
  path : Array[Bytes],
) -> Int64? {
  match self.layout.find(path) {
    Some(file) => Some(file.length)
    None => None
  }
}

///|
pub fn TorrentQuery::leaf_names(self : TorrentQuery) -> Array[Bytes] {
  let result : Array[Bytes] = []
  for file in self.layout.files() {
    result.push(file.leaf())
  }
  result
}

///|
pub fn TorrentQuery::path_components(self : TorrentQuery) -> Int {
  self.layout.total_components()
}

///|
pub fn TorrentQuery::average_file_size(self : TorrentQuery) -> Int64 {
  self.layout.average_file_length()
}

///|
pub fn TorrentQuery::is_piece_aligned(self : TorrentQuery, index : Int) -> Bool {
  self.layout.is_piece_aligned(index)
}

///|
pub fn TorrentQuery::total_piece_spans(self : TorrentQuery) -> Int {
  self.layout.total_piece_spans()
}
