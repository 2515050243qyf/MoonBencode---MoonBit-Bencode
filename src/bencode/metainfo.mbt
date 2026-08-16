///|
/// A normalized path and byte length from a torrent's `info.files` list.
pub(all) struct TorrentFile {
  path : Array[Bytes]
  length : Int64
} derive(Eq, Debug)

///|
/// A validated BitTorrent metainfo document.
pub(all) struct TorrentMeta {
  name : Bytes
  piece_length : Int
  pieces : Bytes
  files : Array[TorrentFile]
  total_length : Int64
  announce : Array[Bytes]
  is_private : Bool
  info : BValue
  info_hash : Bytes
} derive(Eq, Debug)

///|
/// Errors raised by typed metainfo extraction and validation.
pub suberror TorrentError {
  InvalidMetadata(String)
  MissingField(Bytes)
  InvalidPath(Bytes)
} derive(Eq, Debug)

///|
fn dict_lookup(dict : Array[(Bytes, BValue)], key : Bytes) -> BValue? {
  for kv in dict {
    if kv.0 == key {
      return Some(kv.1)
    }
  }
  None
}

///|
fn require_field(
  dict : Array[(Bytes, BValue)],
  key : Bytes,
) -> BValue raise TorrentError {
  match dict_lookup(dict, key) {
    Some(value) => value
    None => raise MissingField(key)
  }
}

///|
fn require_bytes(
  dict : Array[(Bytes, BValue)],
  key : Bytes,
) -> Bytes raise TorrentError {
  match require_field(dict, key) {
    BStr(value) => value
    _ => raise InvalidMetadata("Expected a byte string field")
  }
}

///|
fn require_int(
  dict : Array[(Bytes, BValue)],
  key : Bytes,
) -> Int64 raise TorrentError {
  match require_field(dict, key) {
    BInt(value) => value
    _ => raise InvalidMetadata("Expected an integer field")
  }
}

///|
fn valid_component(component : Bytes) -> Bool {
  if component.length() == 0 || component == b"." || component == b".." {
    return false
  }
  for i = 0; i < component.length(); i = i + 1 {
    if component[i] == b'/' || component[i] == b'\\' || component[i] == 0 {
      return false
    }
  }
  true
}

///|
fn validate_path(path : Array[Bytes]) -> Unit raise TorrentError {
  if path.length() == 0 {
    raise InvalidPath(b"")
  }
  for component in path {
    if !valid_component(component) {
      raise InvalidPath(component)
    }
  }
}

///|
fn parse_path(value : BValue) -> Array[Bytes] raise TorrentError {
  match value {
    BList(parts) => {
      let path : Array[Bytes] = []
      for part in parts {
        match part {
          BStr(component) => path.push(component)
          _ => raise InvalidMetadata("A file path component must be bytes")
        }
      }
      validate_path(path)
      path
    }
    _ => raise InvalidMetadata("A file path must be a list")
  }
}

///|
fn parse_file(value : BValue) -> TorrentFile raise TorrentError {
  match value {
    BDict(dict) => {
      let length = require_int(dict, b"length")
      if length < 0L {
        raise InvalidMetadata("File length cannot be negative")
      }
      let path = parse_path(require_field(dict, b"path"))
      { path, length }
    }
    _ => raise InvalidMetadata("A file entry must be a dictionary")
  }
}

///|
fn parse_files(
  info : Array[(Bytes, BValue)],
) -> (Array[TorrentFile], Int64) raise TorrentError {
  match dict_lookup(info, b"files") {
    Some(BList(values)) => {
      if values.length() == 0 {
        raise InvalidMetadata("A multi-file torrent needs at least one file")
      }
      let files : Array[TorrentFile] = []
      let mut total = 0L
      for value in values {
        let file = parse_file(value)
        if total > 9223372036854775807L - file.length {
          raise InvalidMetadata("Torrent length overflow")
        }
        total += file.length
        files.push(file)
      }
      (files, total)
    }
    Some(_) => raise InvalidMetadata("The files field must be a list")
    None => {
      let name = require_bytes(info, b"name")
      validate_path([name])
      let length = require_int(info, b"length")
      if length < 0L {
        raise InvalidMetadata("File length cannot be negative")
      }
      ([{ path: [name], length }], length)
    }
  }
}

///|
fn parse_announces(
  root : Array[(Bytes, BValue)],
) -> Array[Bytes] raise TorrentError {
  let trackers : Array[Bytes] = []
  match dict_lookup(root, b"announce") {
    Some(BStr(value)) => trackers.push(value)
    Some(_) => raise InvalidMetadata("announce must be a byte string")
    None => ()
  }
  match dict_lookup(root, b"announce-list") {
    Some(BList(tiers)) =>
      for tier in tiers {
        match tier {
          BList(urls) =>
            for url in urls {
              match url {
                BStr(value) => {
                  let mut duplicate = false
                  for existing in trackers {
                    if existing == value {
                      duplicate = true
                    }
                  }
                  if !duplicate {
                    trackers.push(value)
                  }
                }
                _ =>
                  raise InvalidMetadata("announce-list entries must be bytes")
              }
            }
          _ => raise InvalidMetadata("announce-list tiers must be lists")
        }
      }
    Some(_) => raise InvalidMetadata("announce-list must be a list")
    None => ()
  }
  trackers
}

///|
fn parse_private(info : Array[(Bytes, BValue)]) -> Bool raise TorrentError {
  match dict_lookup(info, b"private") {
    None => false
    Some(BInt(value)) =>
      if value == 0L {
        false
      } else if value == 1L {
        true
      } else {
        raise InvalidMetadata("private must be 0 or 1")
      }
    Some(_) => raise InvalidMetadata("private must be an integer")
  }
}

///|
fn validate_piece_length(value : Int64) -> Int raise TorrentError {
  if value < 16384L || value > 16777216L {
    raise InvalidMetadata("piece length must be between 16 KiB and 16 MiB")
  }
  value.to_int()
}

///|
/// Converts a decoded root value into validated typed metainfo.
pub fn TorrentMeta::from_bvalue(
  value : BValue,
) -> TorrentMeta raise TorrentError {
  match value {
    BDict(root) => {
      let info = require_field(root, b"info")
      match info {
        BDict(info_dict) => {
          let name = require_bytes(info_dict, b"name")
          validate_path([name])
          let piece_length = validate_piece_length(
            require_int(info_dict, b"piece length"),
          )
          let pieces = require_bytes(info_dict, b"pieces")
          if pieces.length() % 20 != 0 {
            raise InvalidMetadata("pieces must contain complete 20-byte hashes")
          }
          let (files, total_length) = parse_files(info_dict)
          let expected_pieces = if total_length == 0L {
            0
          } else {
            ((total_length + piece_length.to_int64() - 1L) /
            piece_length.to_int64()).to_int()
          }
          if pieces.length() / 20 != expected_pieces {
            raise InvalidMetadata("pieces count does not match torrent length")
          }
          {
            name,
            piece_length,
            pieces,
            files,
            total_length,
            announce: parse_announces(root),
            is_private: parse_private(info_dict),
            info: BDict(info_dict),
            info_hash: sha1(encode(BDict(info_dict))),
          }
        }
        _ => raise InvalidMetadata("info must be a dictionary")
      }
    }
    _ => raise InvalidMetadata("Torrent root must be a dictionary")
  }
}

///|
pub fn TorrentMeta::piece_count(self : TorrentMeta) -> Int {
  if self.total_length == 0L {
    0
  } else {
    ((self.total_length + self.piece_length.to_int64() - 1L) /
    self.piece_length.to_int64()).to_int()
  }
}

///|
pub fn TorrentMeta::has_tracker(self : TorrentMeta, tracker : Bytes) -> Bool {
  for value in self.announce {
    if value == tracker {
      return true
    }
  }
  false
}

///|
pub fn TorrentMeta::file_named(
  self : TorrentMeta,
  name : Bytes,
) -> TorrentFile? {
  for file in self.files {
    if file.path[file.path.length() - 1] == name {
      return Some(file)
    }
  }
  None
}

///|
pub fn TorrentFile::leaf(self : TorrentFile) -> Bytes {
  self.path[self.path.length() - 1]
}

///|
pub fn TorrentFile::depth(self : TorrentFile) -> Int {
  self.path.length()
}

///|
pub fn TorrentFile::is_empty(self : TorrentFile) -> Bool {
  self.length == 0L
}

///|
pub fn TorrentFile::component(self : TorrentFile, index : Int) -> Bytes? {
  if index < 0 || index >= self.path.length() {
    None
  } else {
    Some(self.path[index])
  }
}
