///|
/// A deterministic builder for v1 BitTorrent metainfo dictionaries.
pub(all) struct TorrentBuilder {
  name : Bytes
  piece_length : Int
  length : Int64?
  files : Array[TorrentFile]?
  pieces : Bytes?
  trackers : Array[Bytes]
  is_private : Bool
} derive(Debug)

///|
pub fn TorrentBuilder::new(name : Bytes, piece_length : Int) -> TorrentBuilder {
  {
    name,
    piece_length,
    length: None,
    files: None,
    pieces: None,
    trackers: [],
    is_private: false,
  }
}

///|
pub fn TorrentBuilder::with_length(
  self : TorrentBuilder,
  length : Int64,
) -> TorrentBuilder {
  { ..self, length: Some(length), files: None }
}

///|
pub fn TorrentBuilder::with_files(
  self : TorrentBuilder,
  files : Array[TorrentFile],
) -> TorrentBuilder {
  { ..self, files: Some(files.copy()), length: None }
}

///|
pub fn TorrentBuilder::with_pieces(
  self : TorrentBuilder,
  pieces : Bytes,
) -> TorrentBuilder {
  { ..self, pieces: Some(pieces) }
}

///|
pub fn TorrentBuilder::with_tracker(
  self : TorrentBuilder,
  tracker : Bytes,
) -> TorrentBuilder {
  let result = self
  for existing in result.trackers {
    if existing == tracker {
      return result
    }
  }
  result.trackers.push(tracker)
  result
}

///|
pub fn TorrentBuilder::set_private(self : TorrentBuilder) -> TorrentBuilder {
  { ..self, is_private: true }
}

///|
pub fn TorrentBuilder::set_public(self : TorrentBuilder) -> TorrentBuilder {
  { ..self, is_private: false }
}

///|
fn TorrentBuilder::file_values(self : TorrentBuilder) -> BValue? {
  match self.files {
    None => None
    Some(files) => {
      let values : Array[BValue] = []
      for file in files {
        let path : Array[BValue] = []
        for part in file.path {
          path.push(BStr(part))
        }
        values.push(
          BDict([(b"length", BInt(file.length)), (b"path", BList(path))]),
        )
      }
      Some(BList(values))
    }
  }
}

///|
fn TorrentBuilder::info_value(
  self : TorrentBuilder,
) -> BValue raise TorrentError {
  let fields : Array[(Bytes, BValue)] = []
  match self.files {
    Some(files) => {
      if files.length() == 0 {
        raise InvalidMetadata("builder needs at least one file")
      }
      match self.file_values() {
        Some(value) => fields.push((b"files", value))
        None => raise InvalidMetadata("builder file list is unavailable")
      }
    }
    None =>
      match self.length {
        Some(length) => {
          if length < 0L {
            raise InvalidMetadata("length cannot be negative")
          }
          fields.push((b"length", BInt(length)))
        }
        None => raise InvalidMetadata("builder needs a length or file list")
      }
  }
  fields.push((b"name", BStr(self.name)))
  fields.push((b"piece length", BInt(self.piece_length.to_int64())))
  match self.pieces {
    Some(pieces) => fields.push((b"pieces", BStr(pieces)))
    None => raise InvalidMetadata("builder needs piece hashes")
  }
  if self.is_private {
    fields.push((b"private", BInt(1L)))
  }
  BDict(fields)
}

///|
pub fn TorrentBuilder::build(
  self : TorrentBuilder,
) -> BValue raise TorrentError {
  let root : Array[(Bytes, BValue)] = []
  if self.trackers.length() > 0 {
    root.push((b"announce", BStr(self.trackers[0])))
    let tier : Array[BValue] = []
    for tracker in self.trackers {
      tier.push(BStr(tracker))
    }
    root.push((b"announce-list", BList([BList(tier)])))
  }
  root.push((b"info", self.info_value()))
  BDict(root)
}

///|
pub fn TorrentBuilder::tracker_count(self : TorrentBuilder) -> Int {
  self.trackers.length()
}

///|
pub fn TorrentBuilder::has_length(self : TorrentBuilder) -> Bool {
  self.length is Some(_)
}

///|
pub fn TorrentBuilder::has_files(self : TorrentBuilder) -> Bool {
  self.files is Some(_)
}

///|
pub fn TorrentBuilder::has_pieces(self : TorrentBuilder) -> Bool {
  self.pieces is Some(_)
}

///|
pub fn TorrentBuilder::is_private(self : TorrentBuilder) -> Bool {
  self.is_private
}

///|
pub fn TorrentBuilder::validate(
  self : TorrentBuilder,
) -> TorrentMeta raise TorrentError {
  TorrentMeta::from_bvalue(self.build())
}

///|
pub fn TorrentBuilder::canonical_bytes(
  self : TorrentBuilder,
) -> Bytes raise TorrentError {
  encode(self.build())
}

///|
pub fn TorrentBuilder::info_hash(
  self : TorrentBuilder,
) -> Bytes raise TorrentError {
  self.validate().info_hash
}

///|
pub fn TorrentBuilder::file_count(self : TorrentBuilder) -> Int {
  match self.files {
    Some(files) => files.length()
    None => 1
  }
}
