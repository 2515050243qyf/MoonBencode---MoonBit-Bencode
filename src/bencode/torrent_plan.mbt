///|
/// A deterministic download planning view over a torrent file layout.
pub(all) struct DownloadPlan {
  piece_size : Int
  piece_count : Int
  total_length : Int64
  file_count : Int
  spans : Int
} derive(Eq, Debug)

///|
pub fn DownloadPlan::from_layout(layout : TorrentLayout) -> DownloadPlan {
  {
    piece_size: layout.piece_size(),
    piece_count: layout.piece_count(),
    total_length: layout.total_length,
    file_count: layout.file_count(),
    spans: layout.total_piece_spans(),
  }
}

///|
pub fn DownloadPlan::piece_count(self : DownloadPlan) -> Int {
  self.piece_count
}

///|
pub fn DownloadPlan::piece_size(self : DownloadPlan) -> Int {
  self.piece_size
}

///|
pub fn DownloadPlan::total_bytes(self : DownloadPlan) -> Int64 {
  self.total_length
}

///|
pub fn DownloadPlan::file_count(self : DownloadPlan) -> Int {
  self.file_count
}

///|
pub fn DownloadPlan::span_count(self : DownloadPlan) -> Int {
  self.spans
}

///|
pub fn DownloadPlan::is_empty(self : DownloadPlan) -> Bool {
  self.total_length == 0L
}

///|
pub fn DownloadPlan::last_piece_length(self : DownloadPlan) -> Int {
  if self.piece_count == 0 {
    0
  } else {
    let remainder = self.total_length % self.piece_size.to_int64()
    if remainder == 0L {
      self.piece_size
    } else {
      remainder.to_int()
    }
  }
}

///|
pub fn DownloadPlan::average_piece_length(self : DownloadPlan) -> Int64 {
  if self.piece_count == 0 {
    0L
  } else {
    self.total_length / self.piece_count.to_int64()
  }
}

///|
pub fn DownloadPlan::is_fragmented(self : DownloadPlan) -> Bool {
  self.spans > self.piece_count
}

///|
pub fn DownloadPlan::fragmentation_ratio(self : DownloadPlan) -> Int {
  if self.piece_count == 0 {
    0
  } else {
    self.spans * 100 / self.piece_count
  }
}

///|
pub fn DownloadPlan::size_class(self : DownloadPlan) -> Bytes {
  if self.total_length < 1048576L {
    b"tiny"
  } else if self.total_length < 1073741824L {
    b"medium"
  } else {
    b"large"
  }
}

///|
pub fn DownloadPlan::piece_class(self : DownloadPlan) -> Bytes {
  if self.piece_count < 10 {
    b"short"
  } else if self.piece_count < 1000 {
    b"normal"
  } else {
    b"long"
  }
}

///|
pub fn DownloadPlan::same_geometry(
  self : DownloadPlan,
  other : DownloadPlan,
) -> Bool {
  self.piece_size == other.piece_size &&
  self.piece_count == other.piece_count &&
  self.spans == other.spans
}

///|
pub fn DownloadPlan::estimated_requests(
  self : DownloadPlan,
  request_size : Int,
) -> Int {
  if request_size <= 0 {
    0
  } else {
    ((self.total_length + request_size.to_int64() - 1L) /
    request_size.to_int64()).to_int()
  }
}

///|
pub fn DownloadPlan::contains_offset(
  self : DownloadPlan,
  offset : Int64,
) -> Bool {
  offset >= 0L && offset < self.total_length
}

///|
pub fn DownloadPlan::piece_for_offset(
  self : DownloadPlan,
  offset : Int64,
) -> Int? {
  if !self.contains_offset(offset) {
    None
  } else {
    Some((offset / self.piece_size.to_int64()).to_int())
  }
}

///|
pub fn DownloadPlan::offset_for_piece(
  self : DownloadPlan,
  piece : Int,
) -> Int64? {
  if piece < 0 || piece >= self.piece_count {
    None
  } else {
    Some(piece.to_int64() * self.piece_size.to_int64())
  }
}

///|
pub fn DownloadPlan::remaining_after_piece(
  self : DownloadPlan,
  piece : Int,
) -> Int64 {
  let end = (piece + 1).to_int64() * self.piece_size.to_int64()
  if end >= self.total_length {
    0L
  } else {
    self.total_length - end
  }
}

///|
pub fn DownloadPlan::completed_ratio(
  self : DownloadPlan,
  completed : Int,
) -> Int {
  if self.piece_count == 0 {
    100
  } else if completed <= 0 {
    0
  } else if completed >= self.piece_count {
    100
  } else {
    completed * 100 / self.piece_count
  }
}

///|
pub fn DownloadPlan::valid_progress(
  self : DownloadPlan,
  completed : Int,
) -> Bool {
  completed >= 0 && completed <= self.piece_count
}

///|
pub fn DownloadPlan::next_piece(self : DownloadPlan, completed : Int) -> Int? {
  if completed < 0 || completed >= self.piece_count {
    None
  } else {
    Some(completed)
  }
}
