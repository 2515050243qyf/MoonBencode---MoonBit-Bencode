///|
test "sha1_test" {
  let h_empty = sha1(b"")
  inspect(
    h_empty,
    content=(
      #|b"\xda9\xa3\xee^kK\x0d2U\xbf\xef\x95`\x18\x90\xaf\xd8\x07\x09"
    ),
  )

  let h_abc = sha1(b"abc")
  inspect(
    h_abc,
    content=(
      #|b"\xa9\x99>6G\x06\x81j\xba>%qxP\xc2l\x9c\xd0\xd8\x9d"
    ),
  )
}

///|
test "torrent_info_hash" {
  let bencode_data = b"d8:announce39:http://torrent.ubuntu.com:6969/announce4:infod5:filesli10ei20ee6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144eee"

  let torrent = decode(bencode_data)
  let h_owned = torrent.info_hash().unwrap()
  inspect(
    h_owned,
    content=(
      #|b"<\x19\x22\xcc\xcb\xf5Z(_\xb4\x89\x156\x96\x9d\x04\xb8\xdc\xbc\xe0"
    ),
  )

  let torrent_view = decode_view(bencode_data)
  let h_view = torrent_view.info_hash().unwrap()
  assert_eq(h_view, h_owned)
}
