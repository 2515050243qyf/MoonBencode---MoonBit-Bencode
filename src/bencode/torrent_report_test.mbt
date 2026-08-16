///|
test "report_summarizes_layout_and_protocol_metadata" {
  let value = decode(
    b"d4:infod6:lengthi16384e4:name8:demo.iso12:piece lengthi16384e6:pieces20:12345678901234567890ee",
  )
  let meta = TorrentMeta::from_bvalue(value)
  let report = TorrentReport::from_meta(meta)
  assert_eq(report.file_count, 1)
  assert_eq(report.piece_count, 1)
  assert_eq(report.total_length, 16384L)
  assert_eq(report.is_multi_file, false)
}
