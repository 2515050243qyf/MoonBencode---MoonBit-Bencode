///|
test "magnet_round_trip_preserves_hash_name_and_trackers" {
  let link = MagnetLink::new(b"12345678901234567890")
  let named = link.with_name(b"Ubuntu 24.04.iso")
  let full = named
    .with_tracker(b"https://tracker.example/announce")
    .with_tracker(b"udp://tracker.example:6969/announce")
  let uri = full.to_uri()
  let parsed = MagnetLink::from_uri(uri)
  assert_eq(parsed.info_hash, b"12345678901234567890")
  assert_eq(parsed.display_name, Some(b"Ubuntu 24.04.iso"))
  assert_eq(parsed.trackers.length(), 2)
}

///|
test "magnet_parser_rejects_missing_or_bad_btih" {
  let mut rejected = false
  try {
    let _ = MagnetLink::from_uri(b"magnet:?dn=missing-hash")
  } catch {
    TorrentError::InvalidMetadata(_) => rejected = true
    _ => ()
  }
  assert_eq(rejected, true)
  let mut bad_hex = false
  try {
    let _ = MagnetLink::from_uri(b"magnet:?xt=urn:btih:zzzz")
  } catch {
    TorrentError::InvalidMetadata(_) => bad_hex = true
    _ => ()
  }
  assert_eq(bad_hex, true)
}

///|
test "magnet_percent_encoding_handles_unicode_bytes" {
  let link = MagnetLink::new(b"12345678901234567890").with_name(
    b"MoonBit æµè¯",
  )
  let uri = link.to_uri()
  assert_eq(uri.view(start=0, end=7).to_owned(), b"magnet:")
  let parsed = MagnetLink::from_uri(uri)
  assert_eq(parsed.display_name, Some(b"MoonBit æµè¯"))
}
