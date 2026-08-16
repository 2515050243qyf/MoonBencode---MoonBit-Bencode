///|
test "query_supports_collection_and_piece_workflows" {
  let value = BValue::BDict([
    (
      b"info",
      BValue::BDict([
        (
          b"files",
          BValue::BList([
            BValue::BDict([
              (b"length", BValue::BInt(3L)),
              (
                b"path",
                BValue::BList([BValue::BStr(b"root"), BValue::BStr(b"a")]),
              ),
            ]),
            BValue::BDict([
              (b"length", BValue::BInt(5L)),
              (
                b"path",
                BValue::BList([BValue::BStr(b"root"), BValue::BStr(b"b")]),
              ),
            ]),
          ]),
        ),
        (b"name", BValue::BStr(b"root")),
        (b"piece length", BValue::BInt(16384L)),
        (b"pieces", BValue::BStr(b"12345678901234567890")),
      ]),
    ),
  ])
  let meta = TorrentMeta::from_bvalue(value)
  let query = TorrentQuery::new(meta)
  assert_eq(query.file_count(), 2)
  assert_eq(query.extension_count(b"bin"), 0)
  assert_eq(query.pieces_in_range(0L, 8L), [0])
  assert_eq(query.directory_size([b"root"]), 8L)
  assert_eq(query.path_exists([b"root", b"a"]), true)
}
