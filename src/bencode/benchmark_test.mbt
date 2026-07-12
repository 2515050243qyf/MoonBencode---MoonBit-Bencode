///|
test "benchmark_decoders" {
  let torrent_data = b"d8:announce39:http://torrent.ubuntu.com:6969/announce4:infod6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144eee"

  // Warm up
  for i = 0; i < 100; i = i + 1 {
    let _ = decode(torrent_data)
    let _ = decode_view(torrent_data)
  }

  let iter_count = 10000

  // Parse owned
  for i = 0; i < iter_count; i = i + 1 {
    let _ = decode(torrent_data)
  }

  // Parse zero-copy view
  for i = 0; i < iter_count; i = i + 1 {
    let _ = decode_view(torrent_data)
  }
}
