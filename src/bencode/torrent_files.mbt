///|
/// A slice of a torrent piece that belongs to one file.
pub(all) struct PieceSpan {
  file_index : Int
  piece_index : Int
  file_offset : Int64
  length : Int
} derive(Eq, Debug)

///|
/// A deterministic file layout used to answer piece and path queries.
pub(all) struct TorrentLayout {
  files : Array[TorrentFile]
  piece_size : Int
  total_length : Int64
} derive(Eq, Debug)

///|
pub fn TorrentLayout::new(
  files : Array[TorrentFile],
  piece_size : Int,
) -> TorrentLayout raise TorrentError {
  if piece_size <= 0 {
    raise InvalidMetadata("piece size must be positive")
  }
  let copied = files.copy()
  let mut total = 0L
  for file in copied {
    validate_layout_file(file)
    if file.length < 0L || total > 9223372036854775807L - file.length {
      raise InvalidMetadata("file layout length overflow")
    }
    total += file.length
  }
  { files: copied, piece_size, total_length: total }
}

///|
fn validate_layout_file(file : TorrentFile) -> Unit raise TorrentError {
  if file.path.length() == 0 {
    raise InvalidPath(b"")
  }
  for part in file.path {
    if part.length() == 0 || part == b"." || part == b".." {
      raise InvalidPath(part)
    }
    for i = 0; i < part.length(); i = i + 1 {
      if part[i] == b'/' || part[i] == b'\\' || part[i] == 0 {
        raise InvalidPath(part)
      }
    }
  }
}

///|
pub fn TorrentLayout::files(self : TorrentLayout) -> Array[TorrentFile] {
  self.files.copy()
}

///|
pub fn TorrentLayout::piece_size(self : TorrentLayout) -> Int {
  self.piece_size
}

///|
pub fn TorrentLayout::piece_count(self : TorrentLayout) -> Int {
  if self.total_length == 0L {
    0
  } else {
    ((self.total_length + self.piece_size.to_int64() - 1L) /
    self.piece_size.to_int64()).to_int()
  }
}

///|
pub fn TorrentLayout::piece_length(self : TorrentLayout, piece : Int) -> Int {
  if piece < 0 || piece >= self.piece_count() {
    return 0
  }
  let start = piece.to_int64() * self.piece_size.to_int64()
  let remaining = self.total_length - start
  if remaining < self.piece_size.to_int64() {
    remaining.to_int()
  } else {
    self.piece_size
  }
}

///|
pub fn TorrentLayout::piece_start(self : TorrentLayout, piece : Int) -> Int64 {
  if piece < 0 {
    0
  } else {
    piece.to_int64() * self.piece_size.to_int64()
  }
}

///|
pub fn TorrentLayout::piece_end(self : TorrentLayout, piece : Int) -> Int64 {
  self.piece_start(piece) + self.piece_length(piece).to_int64()
}

///|
pub fn TorrentLayout::file_start(
  self : TorrentLayout,
  file_index : Int,
) -> Int64 {
  if file_index <= 0 {
    return 0L
  }
  let mut total = 0L
  let limit = if file_index > self.files.length() {
    self.files.length()
  } else {
    file_index
  }
  for i = 0; i < limit; i = i + 1 {
    total += self.files[i].length
  }
  total
}

///|
pub fn TorrentLayout::file_end(self : TorrentLayout, file_index : Int) -> Int64 {
  let length = if file_index < 0 || file_index >= self.files.length() {
    0L
  } else {
    self.files[file_index].length
  }
  self.file_start(file_index) + length
}

///|
pub fn TorrentLayout::file_index_at(
  self : TorrentLayout,
  offset : Int64,
) -> Int? {
  if offset < 0L || offset >= self.total_length {
    return None
  }
  for i = 0; i < self.files.length(); i = i + 1 {
    if offset < self.file_end(i) {
      return Some(i)
    }
  }
  None
}

///|
pub fn TorrentLayout::spans_for_piece(
  self : TorrentLayout,
  piece : Int,
) -> Array[PieceSpan] {
  let spans : Array[PieceSpan] = []
  if piece < 0 || piece >= self.piece_count() {
    return spans
  }
  let start = self.piece_start(piece)
  let end = self.piece_end(piece)
  for i = 0; i < self.files.length(); i = i + 1 {
    let file_start = self.file_start(i)
    let file_end = self.file_end(i)
    if file_end > start && file_start < end {
      let overlap_start = if file_start > start { file_start } else { start }
      let overlap_end = if file_end < end { file_end } else { end }
      spans.push({
        file_index: i,
        piece_index: piece,
        file_offset: overlap_start - file_start,
        length: (overlap_end - overlap_start).to_int(),
      })
    }
  }
  spans
}

///|
pub fn TorrentLayout::pieces_for_file(
  self : TorrentLayout,
  file_index : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  if file_index < 0 || file_index >= self.files.length() {
    return result
  }
  let start = self.file_start(file_index)
  let end = self.file_end(file_index)
  if start == end {
    return result
  }
  let first = (start / self.piece_size.to_int64()).to_int()
  let last = ((end - 1L) / self.piece_size.to_int64()).to_int()
  for piece = first; piece <= last; piece = piece + 1 {
    result.push(piece)
  }
  result
}

///|
fn bytes_prefix(value : Array[Bytes], prefix : Array[Bytes]) -> Bool {
  if prefix.length() > value.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
pub fn TorrentLayout::count_under(
  self : TorrentLayout,
  prefix : Array[Bytes],
) -> Int {
  let mut count = 0
  for file in self.files {
    if bytes_prefix(file.path, prefix) {
      count += 1
    }
  }
  count
}

///|
pub fn TorrentLayout::files_under(
  self : TorrentLayout,
  prefix : Array[Bytes],
) -> Array[TorrentFile] {
  let result : Array[TorrentFile] = []
  for file in self.files {
    if bytes_prefix(file.path, prefix) {
      result.push(file)
    }
  }
  result
}

///|
pub fn TorrentLayout::max_depth(self : TorrentLayout) -> Int {
  let mut result = 0
  for file in self.files {
    if file.path.length() > result {
      result = file.path.length()
    }
  }
  result
}

///|
pub fn TorrentLayout::min_depth(self : TorrentLayout) -> Int {
  if self.files.length() == 0 {
    return 0
  }
  let mut result = self.files[0].path.length()
  for file in self.files {
    if file.path.length() < result {
      result = file.path.length()
    }
  }
  result
}

///|
pub fn TorrentLayout::total_components(self : TorrentLayout) -> Int {
  let mut result = 0
  for file in self.files {
    result += file.path.length()
  }
  result
}

///|
fn has_suffix(value : Bytes, suffix : Bytes) -> Bool {
  if suffix.length() > value.length() {
    return false
  }
  let offset = value.length() - suffix.length()
  for i = 0; i < suffix.length(); i = i + 1 {
    if value[offset + i] != suffix[i] {
      return false
    }
  }
  true
}

///|
pub fn TorrentLayout::count_extension(
  self : TorrentLayout,
  extension : Bytes,
) -> Int {
  let mut count = 0
  let suffix = Bytes::add(b".", extension)
  for file in self.files {
    if has_suffix(file.leaf(), suffix) {
      count += 1
    }
  }
  count
}

///|
pub fn TorrentLayout::largest_file(self : TorrentLayout) -> TorrentFile? {
  if self.files.length() == 0 {
    return None
  }
  let mut result = self.files[0]
  for file in self.files {
    if file.length > result.length {
      result = file
    }
  }
  Some(result)
}

///|
pub fn TorrentLayout::smallest_file(self : TorrentLayout) -> TorrentFile? {
  if self.files.length() == 0 {
    return None
  }
  let mut result = self.files[0]
  for file in self.files {
    if file.length < result.length {
      result = file
    }
  }
  Some(result)
}

///|
pub fn TorrentLayout::empty_file_count(self : TorrentLayout) -> Int {
  let mut result = 0
  for file in self.files {
    if file.length == 0L {
      result += 1
    }
  }
  result
}

///|
pub fn TorrentLayout::directory_count(self : TorrentLayout) -> Int {
  let directories : Array[Array[Bytes]] = []
  for file in self.files {
    for depth = 1; depth < file.path.length(); depth = depth + 1 {
      let prefix = file.path[:depth].to_owned()
      let mut known = false
      for existing in directories {
        if existing == prefix {
          known = true
        }
      }
      if !known {
        directories.push(prefix)
      }
    }
  }
  directories.length()
}

///|
pub fn TorrentLayout::validate_unique_paths(
  self : TorrentLayout,
) -> Unit raise TorrentError {
  for i = 0; i < self.files.length(); i = i + 1 {
    for j = i + 1; j < self.files.length(); j = j + 1 {
      if self.files[i].path == self.files[j].path {
        raise InvalidMetadata("Torrent contains duplicate file paths")
      }
    }
  }
}

///|
pub fn TorrentLayout::find(
  self : TorrentLayout,
  path : Array[Bytes],
) -> TorrentFile? {
  for file in self.files {
    if file.path == path {
      return Some(file)
    }
  }
  None
}

///|
pub fn TorrentLayout::contains(
  self : TorrentLayout,
  path : Array[Bytes],
) -> Bool {
  self.find(path) is Some(_)
}

///|
pub fn TorrentLayout::file_count(self : TorrentLayout) -> Int {
  self.files.length()
}

///|
pub fn TorrentLayout::is_single_file(self : TorrentLayout) -> Bool {
  self.files.length() == 1 && self.files[0].path.length() == 1
}

///|
pub fn TorrentLayout::is_multi_file(self : TorrentLayout) -> Bool {
  !self.is_single_file()
}

///|
pub fn TorrentLayout::average_file_length(self : TorrentLayout) -> Int64 {
  if self.files.length() == 0 {
    0L
  } else {
    self.total_length / self.files.length().to_int64()
  }
}

///|
pub fn TorrentLayout::piece_utilization(
  self : TorrentLayout,
  piece : Int,
) -> Int {
  if self.piece_size == 0 {
    0
  } else {
    self.piece_length(piece) * 100 / self.piece_size
  }
}

///|
pub fn TorrentLayout::is_piece_aligned(
  self : TorrentLayout,
  file_index : Int,
) -> Bool {
  self.file_start(file_index) % self.piece_size.to_int64() == 0L
}

///|
pub fn TorrentLayout::total_piece_spans(self : TorrentLayout) -> Int {
  let mut result = 0
  for piece = 0; piece < self.piece_count(); piece = piece + 1 {
    result += self.spans_for_piece(piece).length()
  }
  result
}
