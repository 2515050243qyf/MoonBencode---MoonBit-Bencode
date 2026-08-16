///|
/// A lightweight in-memory catalog for comparing torrent metadata.
pub(all) struct TorrentCatalogEntry {
  name : Bytes
  info_hash : Bytes
  total_length : Int64
  file_count : Int
  piece_count : Int
  is_private : Bool
} derive(Eq, Debug)

///|
pub(all) struct TorrentCatalog {
  entries : Array[TorrentCatalogEntry]
} derive(Eq, Debug)

///|
pub fn TorrentCatalog::new() -> TorrentCatalog {
  { entries: [] }
}

///|
pub fn TorrentCatalog::add(
  self : TorrentCatalog,
  meta : TorrentMeta,
) -> TorrentCatalog {
  let entry = {
    name: meta.name,
    info_hash: meta.info_hash,
    total_length: meta.total_length,
    file_count: meta.files.length(),
    piece_count: meta.piece_count(),
    is_private: meta.is_private,
  }
  for existing in self.entries {
    if existing.info_hash == entry.info_hash {
      return self
    }
  }
  self.entries.push(entry)
  self
}

///|
pub fn TorrentCatalog::add_value(
  self : TorrentCatalog,
  value : BValue,
) -> TorrentCatalog raise TorrentError {
  self.add(TorrentMeta::from_bvalue(value))
}

///|
pub fn TorrentCatalog::size(self : TorrentCatalog) -> Int {
  self.entries.length()
}

///|
pub fn TorrentCatalog::is_empty(self : TorrentCatalog) -> Bool {
  self.entries.length() == 0
}

///|
pub fn TorrentCatalog::contains_hash(
  self : TorrentCatalog,
  info_hash : Bytes,
) -> Bool {
  for entry in self.entries {
    if entry.info_hash == info_hash {
      return true
    }
  }
  false
}

///|
pub fn TorrentCatalog::find_hash(
  self : TorrentCatalog,
  info_hash : Bytes,
) -> TorrentCatalogEntry? {
  for entry in self.entries {
    if entry.info_hash == info_hash {
      return Some(entry)
    }
  }
  None
}

///|
pub fn TorrentCatalog::find_name(
  self : TorrentCatalog,
  name : Bytes,
) -> Array[TorrentCatalogEntry] {
  let result : Array[TorrentCatalogEntry] = []
  for entry in self.entries {
    if entry.name == name {
      result.push(entry)
    }
  }
  result
}

///|
pub fn TorrentCatalog::private_count(self : TorrentCatalog) -> Int {
  let mut result = 0
  for entry in self.entries {
    if entry.is_private {
      result += 1
    }
  }
  result
}

///|
pub fn TorrentCatalog::total_bytes(self : TorrentCatalog) -> Int64 {
  let mut result = 0L
  for entry in self.entries {
    result += entry.total_length
  }
  result
}

///|
pub fn TorrentCatalog::total_files(self : TorrentCatalog) -> Int {
  let mut result = 0
  for entry in self.entries {
    result += entry.file_count
  }
  result
}

///|
pub fn TorrentCatalog::largest(self : TorrentCatalog) -> TorrentCatalogEntry? {
  if self.entries.length() == 0 {
    return None
  }
  let mut result = self.entries[0]
  for entry in self.entries {
    if entry.total_length > result.total_length {
      result = entry
    }
  }
  Some(result)
}

///|
pub fn TorrentCatalog::smallest(self : TorrentCatalog) -> TorrentCatalogEntry? {
  if self.entries.length() == 0 {
    return None
  }
  let mut result = self.entries[0]
  for entry in self.entries {
    if entry.total_length < result.total_length {
      result = entry
    }
  }
  Some(result)
}

///|
pub fn TorrentCatalog::piece_total(self : TorrentCatalog) -> Int {
  let mut result = 0
  for entry in self.entries {
    result += entry.piece_count
  }
  result
}

///|
pub fn TorrentCatalog::average_size(self : TorrentCatalog) -> Int64 {
  if self.entries.length() == 0 {
    0L
  } else {
    self.total_bytes() / self.entries.length().to_int64()
  }
}

///|
pub fn TorrentCatalog::merge(
  self : TorrentCatalog,
  other : TorrentCatalog,
) -> TorrentCatalog {
  let result = self
  for entry in other.entries {
    if !result.contains_hash(entry.info_hash) {
      result.entries.push(entry)
    }
  }
  result
}

///|
pub fn TorrentCatalog::sorted_by_size(
  self : TorrentCatalog,
) -> Array[TorrentCatalogEntry] {
  let result = self.entries.copy()
  result.sort_by(fn(a, b) {
    if a.total_length < b.total_length {
      -1
    } else if a.total_length > b.total_length {
      1
    } else {
      0
    }
  })
  result
}

///|
pub fn TorrentCatalog::sorted_by_name(
  self : TorrentCatalog,
) -> Array[TorrentCatalogEntry] {
  let result = self.entries.copy()
  result.sort_by(fn(a, b) {
    if a.name < b.name {
      -1
    } else if a.name > b.name {
      1
    } else {
      0
    }
  })
  result
}

///|
pub fn TorrentCatalog::remove_hash(
  self : TorrentCatalog,
  info_hash : Bytes,
) -> TorrentCatalog {
  let result : Array[TorrentCatalogEntry] = []
  for entry in self.entries {
    if entry.info_hash != info_hash {
      result.push(entry)
    }
  }
  { entries: result }
}

///|
pub fn TorrentCatalogEntry::is_large(
  self : TorrentCatalogEntry,
  threshold : Int64,
) -> Bool {
  self.total_length >= threshold
}

///|
pub fn TorrentCatalogEntry::same_content(
  self : TorrentCatalogEntry,
  other : TorrentCatalogEntry,
) -> Bool {
  self.info_hash == other.info_hash
}

///|
pub fn TorrentCatalogEntry::scale(self : TorrentCatalogEntry) -> Bytes {
  if self.total_length < 1048576L {
    b"small"
  } else if self.total_length < 1073741824L {
    b"medium"
  } else {
    b"large"
  }
}
