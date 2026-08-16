///|
test "metainfo_extracts_single_file_torrent" {
  let value = decode(
    b"d4:infod6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144e6:pieces80:12345678901234567890123456789012345678901234567890123456789012345678901234567890ee",
  )
  let meta = TorrentMeta::from_bvalue(value)
  assert_eq(meta.name, b"ubuntu.iso")
  assert_eq(meta.piece_length, 262144)
  assert_eq(meta.files.length(), 1)
  assert_eq(meta.total_length, 1048576L)
  assert_eq(meta.files[0].path, [b"ubuntu.iso"])
}

///|
test "metainfo_extracts_multi_file_layout_and_private_flag" {
  let value = BValue::BDict([
    (b"announce", BValue::BStr(b"http://tracker")),
    (
      b"info",
      BValue::BDict([
        (
          b"files",
          BValue::BList([
            BValue::BDict([
              (b"length", BValue::BInt(3L)),
              (b"path", BValue::BList([BValue::BStr(b"a.txt")])),
            ]),
            BValue::BDict([
              (b"length", BValue::BInt(5L)),
              (b"path", BValue::BList([BValue::BStr(b"b.bin")])),
            ]),
          ]),
        ),
        (b"name", BValue::BStr(b"root")),
        (b"piece length", BValue::BInt(16384L)),
        (b"pieces", BValue::BStr(b"12345678901234567890")),
        (b"private", BValue::BInt(1L)),
      ]),
    ),
  ])
  let meta = TorrentMeta::from_bvalue(value)
  assert_eq(meta.name, b"root")
  assert_eq(meta.files.length(), 2)
  assert_eq(meta.total_length, 8L)
  assert_eq(meta.is_private, true)
  assert_eq(meta.announce.length(), 1)
}

///|
test "metainfo_rejects_invalid_piece_length_and_paths" {
  let invalid = decode(
    b"d4:infod6:lengthi1e4:name1:x12:piece lengthi3e6:pieces0:ee",
  )
  let mut rejected = false
  try {
    let _ = TorrentMeta::from_bvalue(invalid)
  } catch {
    TorrentError::InvalidMetadata(_) => rejected = true
    _ => ()
  }
  assert_eq(rejected, true)
}
