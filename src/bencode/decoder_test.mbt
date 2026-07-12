///|
test "decode_integer" {
  let val = decode(b"i42e")
  assert_eq(val, BValue::BInt(42L))
  let val_neg = decode(b"i-42e")
  assert_eq(val_neg, BValue::BInt(-42L))
  let val_zero = decode(b"i0e")
  assert_eq(val_zero, BValue::BInt(0L))
}

///|
test "decode_string" {
  let val = decode(b"4:spam")
  assert_eq(val, BValue::BStr(b"spam"))
  let val_empty = decode(b"0:")
  assert_eq(val_empty, BValue::BStr(b""))
}

///|
test "decode_list" {
  let val = decode(b"l4:spami42ee")
  assert_eq(val, BValue::BList([BValue::BStr(b"spam"), BValue::BInt(42L)]))
  let val_empty = decode(b"le")
  assert_eq(val_empty, BValue::BList([]))
}

///|
test "decode_dict" {
  let val = decode(b"d3:bar4:spam3:fooi42ee")
  assert_eq(
    val,
    BValue::BDict([(b"bar", BValue::BStr(b"spam")), (b"foo", BValue::BInt(42L))]),
  )
  let val_empty = decode(b"de")
  assert_eq(val_empty, BValue::BDict([]))
}

///|
test "decode_nested" {
  // list containing a dict and an int
  let val = decode(b"ld3:bar4:spamei42ee")
  assert_eq(
    val,
    BValue::BList([
      BValue::BDict([(b"bar", BValue::BStr(b"spam"))]),
      BValue::BInt(42L),
    ]),
  )
}

///|

///|
test "decode_malformed_errors" {
  let mut err = false
  try {
    let _ = decode(b"i42") // missing 'e'
  } catch {
    DecodeError::UnexpectedEOF => err = true
    _ => ()
  }
  assert_eq(err, true)

  let mut err2 = false
  try {
    let _ = decode(b"di42e4:spame") // dict key must be string
  } catch {
    DecodeError::InvalidFormat(_) => err2 = true
    _ => ()
  }
  assert_eq(err2, true)
}

///|
test "decode_strict_validation" {
  // 1. leading zero in integer
  let mut err = false
  try {
    let _ = decode(b"i03e")
  } catch {
    DecodeError::InvalidFormat(_) => err = true
    _ => ()
  }
  assert_eq(err, true)

  // 2. negative zero in integer
  let mut err_neg_zero = false
  try {
    let _ = decode(b"i-0e")
  } catch {
    DecodeError::InvalidFormat(_) => err_neg_zero = true
    _ => ()
  }
  assert_eq(err_neg_zero, true)

  // 3. integer overflow
  let mut err_overflow = false
  try {
    let _ = decode(b"i9223372036854775808e")
  } catch {
    DecodeError::InvalidFormat(_) => err_overflow = true
    _ => ()
  }
  assert_eq(err_overflow, true)

  // 4. string length leading zeros
  let mut err_str_leading = false
  try {
    let _ = decode(b"04:spam")
  } catch {
    DecodeError::InvalidFormat(_) => err_str_leading = true
    _ => ()
  }
  assert_eq(err_str_leading, true)

  // 5. non-canonical dict sorting
  let mut err_sorting = false
  try {
    let _ = decode(b"d3:fooi42e3:bar4:spame") // 'foo' before 'bar'
  } catch {
    DecodeError::InvalidFormat(_) => err_sorting = true
    _ => ()
  }
  assert_eq(err_sorting, true)

  // 6. duplicate dict key
  let mut err_duplicate = false
  try {
    let _ = decode(b"d3:bar4:spam3:bar4:spame")
  } catch {
    DecodeError::InvalidFormat(_) => err_duplicate = true
    _ => ()
  }
  assert_eq(err_duplicate, true)
}

///|
test "decode_depth_limit" {
  let mut deep = b""
  for i = 0; i < 1005; i = i + 1 {
    deep = Bytes::add(deep, b"l")
  }
  for i = 0; i < 1005; i = i + 1 {
    deep = Bytes::add(deep, b"e")
  }
  let mut err = false
  try {
    let _ = decode(deep)
  } catch {
    DecodeError::InvalidFormat(_) => err = true
    _ => ()
  }
  assert_eq(err, true)
}

///|
test "decode_view_zero_copy" {
  let bytes = b"d3:bar4:spam3:fooi42ee"
  let val_view = decode_view(bytes)
  let expected = BValueView::BDict([
    (bytes.view(start=3, end=6), BValueView::BStr(bytes.view(start=8, end=12))),
    (bytes.view(start=14, end=17), BValueView::BInt(42L)),
  ])
  assert_eq(val_view, expected)

  let val_owned = val_view.to_bvalue()
  assert_eq(val_owned, decode(bytes))
}

///|
test "decode_real_torrent_sample" {
  let torrent_data = b"d8:announce39:http://torrent.ubuntu.com:6969/announce4:infod6:lengthi1048576e4:name10:ubuntu.iso12:piece lengthi262144eee"
  let val = decode(torrent_data)

  match val {
    BDict(dict) => {
      assert_eq(dict.length(), 2)
      assert_eq(dict[0].0, b"announce")
      match dict[0].1 {
        BStr(url) => assert_eq(url, b"http://torrent.ubuntu.com:6969/announce")
        _ => fail("announce must be a string")
      }
      assert_eq(dict[1].0, b"info")
      match dict[1].1 {
        BDict(info) => {
          assert_eq(info.length(), 3)
          assert_eq(info[0].0, b"length")
          assert_eq(info[0].1, BValue::BInt(1048576L))
          assert_eq(info[1].0, b"name")
          assert_eq(info[1].1, BValue::BStr(b"ubuntu.iso"))
          assert_eq(info[2].0, b"piece length")
          assert_eq(info[2].1, BValue::BInt(262144L))
        }
        _ => fail("info must be a dictionary")
      }
    }
    _ => fail("torrent must be a dictionary")
  }
}
