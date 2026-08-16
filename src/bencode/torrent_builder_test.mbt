///|
test "builder_creates_canonical_single_file_metainfo" {
  let builder = TorrentBuilder::new(b"demo.iso", 16384)
    .with_length(16384L)
    .with_pieces(b"12345678901234567890")
    .with_tracker(b"https://tracker.example/announce")
  let value = builder.build()
  let meta = TorrentMeta::from_bvalue(value)
  assert_eq(meta.name, b"demo.iso")
  assert_eq(meta.total_length, 16384L)
  assert_eq(meta.announce.length(), 1)
}

///|
test "builder_creates_multi_file_private_metainfo" {
  let files : Array[TorrentFile] = [
    { path: [b"root", b"a"], length: 4L },
    { path: [b"root", b"b"], length: 4L },
  ]
  let value = TorrentBuilder::new(b"root", 16384)
    .with_files(files)
    .with_pieces(b"12345678901234567890")
    .set_private()
    .build()
  let meta = TorrentMeta::from_bvalue(value)
  assert_eq(meta.files.length(), 2)
  assert_eq(meta.is_private, true)
}
