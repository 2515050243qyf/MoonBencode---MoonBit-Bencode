///|
test "file_layout_maps_piece_spans_across_files" {
  let files : Array[TorrentFile] = [
    { path: [b"root", b"a.bin"], length: 5L },
    { path: [b"root", b"b.bin"], length: 7L },
  ]
  let layout = TorrentLayout::new(files, 4)
  assert_eq(layout.total_length, 12L)
  assert_eq(layout.piece_count(), 3)
  assert_eq(layout.piece_length(0), 4)
  assert_eq(layout.piece_length(2), 4)
  let spans = layout.spans_for_piece(1)
  assert_eq(spans.length(), 2)
  assert_eq(spans[0].file_index, 0)
  assert_eq(spans[0].length, 1)
  assert_eq(spans[1].file_index, 1)
  assert_eq(spans[1].length, 3)
}

///|
test "file_layout_rejects_unsafe_paths" {
  let mut rejected = false
  try {
    let unsafe_file : TorrentFile = { path: [b"..", b"secret"], length: 1L }
    let _ = TorrentLayout::new([unsafe_file], 4)
  } catch {
    TorrentError::InvalidPath(_) => rejected = true
    _ => ()
  }
  assert_eq(rejected, true)
}

///|
test "file_layout_reports_directory_and_extension_statistics" {
  let files : Array[TorrentFile] = [
    { path: [b"root", b"docs", b"readme.md"], length: 10L },
    { path: [b"root", b"src", b"main.mbt"], length: 20L },
    { path: [b"root", b"src", b"lib.mbt"], length: 30L },
  ]
  let layout = TorrentLayout::new(files, 16)
  assert_eq(layout.max_depth(), 3)
  assert_eq(layout.count_extension(b"mbt"), 2)
  assert_eq(layout.count_under([b"root", b"src"]), 2)
}
