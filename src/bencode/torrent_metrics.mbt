///|
/// Collection-oriented metrics for dashboards and acceptance reports.
pub(all) struct TorrentMetrics {
  file_count : Int
  total_length : Int64
  piece_count : Int
  zero_length_files : Int
  max_depth : Int
  directory_count : Int
  extension_counts : Array[(Bytes, Int)]
  depth_counts : Array[(Int, Int)]
} derive(Eq, Debug)

///|
pub fn TorrentMetrics::from_meta(
  meta : TorrentMeta,
) -> TorrentMetrics raise TorrentError {
  let layout = TorrentLayout::new(meta.files, meta.piece_length)
  {
    file_count: layout.file_count(),
    total_length: layout.total_length,
    piece_count: layout.piece_count(),
    zero_length_files: layout.empty_file_count(),
    max_depth: layout.max_depth(),
    directory_count: layout.directory_count(),
    extension_counts: build_extension_counts(layout.files()),
    depth_counts: build_depth_counts(layout.files()),
  }
}

///|
fn extension_of(name : Bytes) -> Bytes? {
  let mut separator : Int? = None
  for i = 0; i < name.length(); i = i + 1 {
    if name[i] == b'.' {
      separator = Some(i)
    }
  }
  match separator {
    Some(index) =>
      if index + 1 < name.length() {
        Some(name.view(start=index + 1, end=name.length()).to_owned())
      } else {
        None
      }
    None => None
  }
}

///|
fn increment_extension(counts : Array[(Bytes, Int)], extension : Bytes) -> Unit {
  for i = 0; i < counts.length(); i = i + 1 {
    if counts[i].0 == extension {
      counts[i] = (extension, counts[i].1 + 1)
      return
    }
  }
  counts.push((extension, 1))
}

///|
fn build_extension_counts(files : Array[TorrentFile]) -> Array[(Bytes, Int)] {
  let counts : Array[(Bytes, Int)] = []
  for file in files {
    match extension_of(file.leaf()) {
      Some(value) => increment_extension(counts, value)
      None => ()
    }
  }
  counts.sort_by(fn(a, b) {
    if a.0 < b.0 {
      -1
    } else if a.0 > b.0 {
      1
    } else {
      0
    }
  })
  counts
}

///|
fn increment_depth(counts : Array[(Int, Int)], depth : Int) -> Unit {
  for i = 0; i < counts.length(); i = i + 1 {
    if counts[i].0 == depth {
      counts[i] = (depth, counts[i].1 + 1)
      return
    }
  }
  counts.push((depth, 1))
}

///|
fn build_depth_counts(files : Array[TorrentFile]) -> Array[(Int, Int)] {
  let counts : Array[(Int, Int)] = []
  for file in files {
    increment_depth(counts, file.depth())
  }
  counts.sort_by(fn(a, b) { a.0 - b.0 })
  counts
}

///|
pub fn TorrentMetrics::extension_count(
  self : TorrentMetrics,
  extension : Bytes,
) -> Int {
  for pair in self.extension_counts {
    if pair.0 == extension {
      return pair.1
    }
  }
  0
}

///|
pub fn TorrentMetrics::depth_count(self : TorrentMetrics, depth : Int) -> Int {
  for pair in self.depth_counts {
    if pair.0 == depth {
      return pair.1
    }
  }
  0
}

///|
pub fn TorrentMetrics::has_extension(
  self : TorrentMetrics,
  extension : Bytes,
) -> Bool {
  self.extension_count(extension) > 0
}

///|
pub fn TorrentMetrics::extension_kinds(self : TorrentMetrics) -> Int {
  self.extension_counts.length()
}

///|
pub fn TorrentMetrics::depth_kinds(self : TorrentMetrics) -> Int {
  self.depth_counts.length()
}

///|
pub fn TorrentMetrics::average_file_size(self : TorrentMetrics) -> Int64 {
  if self.file_count == 0 {
    0L
  } else {
    self.total_length / self.file_count.to_int64()
  }
}

///|
pub fn TorrentMetrics::average_piece_size(self : TorrentMetrics) -> Int64 {
  if self.piece_count == 0 {
    0L
  } else {
    self.total_length / self.piece_count.to_int64()
  }
}

///|
pub fn TorrentMetrics::empty_ratio(self : TorrentMetrics) -> Int {
  if self.file_count == 0 {
    0
  } else {
    self.zero_length_files * 100 / self.file_count
  }
}

///|
pub fn TorrentMetrics::nested_ratio(self : TorrentMetrics) -> Int {
  if self.file_count == 0 {
    0
  } else {
    (self.file_count - self.depth_count(1)) * 100 / self.file_count
  }
}

///|
pub fn TorrentMetrics::largest_extension_count(self : TorrentMetrics) -> Int {
  let mut result = 0
  for pair in self.extension_counts {
    if pair.1 > result {
      result = pair.1
    }
  }
  result
}

///|
pub fn TorrentMetrics::most_common_extension(self : TorrentMetrics) -> Bytes? {
  if self.extension_counts.length() == 0 {
    return None
  }
  let mut result = self.extension_counts[0]
  for pair in self.extension_counts {
    if pair.1 > result.1 {
      result = pair
    }
  }
  Some(result.0)
}

///|
pub fn TorrentMetrics::is_balanced(self : TorrentMetrics) -> Bool {
  self.extension_kinds() <= 1 ||
  self.largest_extension_count() * 2 <= self.file_count
}

///|
pub fn TorrentMetrics::scale(self : TorrentMetrics) -> Bytes {
  if self.total_length < 1048576L {
    b"small"
  } else if self.total_length < 1073741824L {
    b"medium"
  } else {
    b"large"
  }
}

///|
pub fn TorrentMetrics::complexity(self : TorrentMetrics) -> Bytes {
  if self.file_count > 10000 || self.max_depth > 32 {
    b"high"
  } else if self.file_count > 100 || self.max_depth > 8 {
    b"medium"
  } else {
    b"low"
  }
}

///|
pub fn TorrentMetrics::same_shape(
  self : TorrentMetrics,
  other : TorrentMetrics,
) -> Bool {
  self.file_count == other.file_count &&
  self.max_depth == other.max_depth &&
  self.extension_kinds() == other.extension_kinds()
}

///|
pub fn TorrentMetrics::merge(
  self : TorrentMetrics,
  other : TorrentMetrics,
) -> TorrentMetrics {
  let merged_extensions = self.extension_counts.copy()
  for pair in other.extension_counts {
    let mut found = false
    for i = 0; i < merged_extensions.length(); i = i + 1 {
      if merged_extensions[i].0 == pair.0 {
        merged_extensions[i] = (pair.0, merged_extensions[i].1 + pair.1)
        found = true
      }
    }
    if !found {
      merged_extensions.push(pair)
    }
  }
  {
    file_count: self.file_count + other.file_count,
    total_length: self.total_length + other.total_length,
    piece_count: self.piece_count + other.piece_count,
    zero_length_files: self.zero_length_files + other.zero_length_files,
    max_depth: if self.max_depth > other.max_depth {
      self.max_depth
    } else {
      other.max_depth
    },
    directory_count: self.directory_count + other.directory_count,
    extension_counts: merged_extensions,
    depth_counts: self.depth_counts,
  }
}
