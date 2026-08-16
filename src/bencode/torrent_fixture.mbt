///|
/// Deterministic protocol fixtures used by examples and integration tests.
pub fn fixture_single_file(
  name : Bytes,
  length : Int64,
  piece_length : Int,
) -> BValue {
  let piece_count = if length == 0L {
    0
  } else {
    ((length + piece_length.to_int64() - 1L) / piece_length.to_int64()).to_int()
  }
  let pieces : Array[Byte] = []
  for i = 0; i < piece_count * 20; i = i + 1 {
    pieces.push((i % 251).to_byte())
  }
  BDict([
    (
      b"info",
      BDict([
        (b"length", BInt(length)),
        (b"name", BStr(name)),
        (b"piece length", BInt(piece_length.to_int64())),
        (b"pieces", BStr(Bytes::from_array(pieces))),
      ]),
    ),
  ])
}

///|
pub fn fixture_multi_file(
  name : Bytes,
  files : Array[TorrentFile],
  piece_length : Int,
) -> BValue {
  let values : Array[BValue] = []
  let mut total = 0L
  for file in files {
    let path : Array[BValue] = []
    for part in file.path {
      path.push(BStr(part))
    }
    values.push(BDict([(b"length", BInt(file.length)), (b"path", BList(path))]))
    total += file.length
  }
  let count = if total == 0L {
    0
  } else {
    ((total + piece_length.to_int64() - 1L) / piece_length.to_int64()).to_int()
  }
  let pieces : Array[Byte] = []
  for i = 0; i < count * 20; i = i + 1 {
    pieces.push((i * 17 % 251).to_byte())
  }
  BDict([
    (
      b"info",
      BDict([
        (b"files", BList(values)),
        (b"name", BStr(name)),
        (b"piece length", BInt(piece_length.to_int64())),
        (b"pieces", BStr(Bytes::from_array(pieces))),
      ]),
    ),
  ])
}

///|
pub fn fixture_linux_iso() -> BValue {
  fixture_with_tracker(
    fixture_single_file(b"ubuntu.iso", 2097152L, 16384),
    b"https://torrent.ubuntu.com/announce",
  )
}

///|
pub fn fixture_source_tree() -> BValue {
  fixture_multi_file(
    b"moonbencode",
    [
      { path: [b"moonbencode", b"README.md"], length: 12000L },
      { path: [b"moonbencode", b"src", b"decoder.mbt"], length: 24000L },
      { path: [b"moonbencode", b"src", b"encoder.mbt"], length: 8000L },
      { path: [b"moonbencode", b"tests", b"fixtures.bin"], length: 4096L },
    ],
    16384,
  )
}

///|
pub fn fixture_private_tree() -> BValue raise TorrentError {
  let value = fixture_source_tree()
  set_private(value, true)
}

///|
pub fn fixture_with_tracker(value : BValue, tracker : Bytes) -> BValue {
  add_tracker(value, tracker)
}

///|
pub fn fixture_with_name(
  value : BValue,
  name : Bytes,
) -> BValue raise TorrentError {
  rename_torrent(value, name)
}

///|
pub fn fixture_empty_file() -> BValue {
  fixture_single_file(b"empty.bin", 0L, 16384)
}

///|
pub fn fixture_nested_tree() -> BValue {
  fixture_multi_file(
    b"nested",
    [
      { path: [b"nested", b"a", b"b", b"c.txt"], length: 12L },
      { path: [b"nested", b"a", b"d", b"e.txt"], length: 24L },
    ],
    16384,
  )
}

///|
pub fn fixture_torrent_bytes(value : BValue) -> Bytes {
  encode(value)
}

///|
pub fn fixture_round_trip(value : BValue) -> BValue raise DecodeError {
  decode(fixture_torrent_bytes(value))
}

///|
pub fn fixture_profile(value : BValue) -> BValueProfile {
  profile(value)
}

///|
pub fn fixture_is_canonical(value : BValue) -> Bool {
  encode(value) == canonical_bytes(value)
}

///|
pub fn fixture_file_count(value : BValue) -> Int raise TorrentError {
  TorrentMeta::from_bvalue(value).files.length()
}

///|
pub fn fixture_piece_count(value : BValue) -> Int raise TorrentError {
  TorrentMeta::from_bvalue(value).piece_count()
}

///|
pub fn fixture_info_hash(value : BValue) -> Bytes raise TorrentError {
  TorrentMeta::from_bvalue(value).info_hash
}

///|
pub fn fixture_is_private(value : BValue) -> Bool raise TorrentError {
  TorrentMeta::from_bvalue(value).is_private
}

///|
pub fn fixture_has_nested_paths(value : BValue) -> Bool raise TorrentError {
  TorrentLayout::new(
    TorrentMeta::from_bvalue(value).files,
    TorrentMeta::from_bvalue(value).piece_length,
  ).max_depth() >
  1
}

///|
pub fn fixture_add_announce_list(
  value : BValue,
  trackers : Array[Bytes],
) -> BValue {
  match value {
    BDict(root) => {
      let urls : Array[BValue] = []
      for tracker in trackers {
        urls.push(BStr(tracker))
      }
      BDict(replace_field(root, b"announce-list", BList([BList(urls)])))
    }
    _ => value
  }
}
