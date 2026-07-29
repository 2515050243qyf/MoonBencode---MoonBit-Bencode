///|
test "bvalue_get_path" {
  let bencode_data = b"d8:announce39:http://torrent.ubuntu.com:6969/announce4:infod5:filesli10ei20ee6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144eee"
  let torrent = decode(bencode_data)

  // Test directory/dictionary lookups
  assert_eq(
    torrent.get_path(["info", "name"]),
    Some(BValue::BStr(b"ubuntu.iso")),
  )
  assert_eq(
    torrent.get_path(["info", "piece length"]),
    Some(BValue::BInt(262144L)),
  )

  // Test list index lookup
  assert_eq(torrent.get_path(["info", "files", "1"]), Some(BValue::BInt(20L)))

  // Test invalid key/index lookups
  assert_eq(torrent.get_path(["info", "nonexistent"]), None)
  assert_eq(torrent.get_path(["info", "files", "3"]), None)
  assert_eq(torrent.get_path(["info", "files", "not_an_int"]), None)
}

///|
test "bvalue_view_get_path" {
  let bencode_data = b"d8:announce39:http://torrent.ubuntu.com:6969/announce4:infod5:filesli10ei20ee6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144eee"
  let torrent_view = decode_view(bencode_data)

  // Test lookups on view
  assert_eq(
    torrent_view.get_path(["info", "name"]).map(BValueView::to_bvalue),
    Some(BValue::BStr(b"ubuntu.iso")),
  )
  assert_eq(
    torrent_view.get_path(["info", "files", "0"]).map(BValueView::to_bvalue),
    Some(BValue::BInt(10L)),
  )
  assert_eq(torrent_view.get_path(["info", "nonexistent"]), None)
}
