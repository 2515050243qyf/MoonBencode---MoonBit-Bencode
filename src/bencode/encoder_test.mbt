test "encode_integer" {
  assert_eq(encode(BValue::BInt(42L)), b"i42e")
  assert_eq(encode(BValue::BInt(-42L)), b"i-42e")
  assert_eq(encode(BValue::BInt(0L)), b"i0e")
}

test "encode_string" {
  assert_eq(encode(BValue::BStr(b"spam")), b"4:spam")
  assert_eq(encode(BValue::BStr(b"")), b"0:")
}

test "encode_list" {
  assert_eq(encode(BValue::BList([BValue::BStr(b"spam"), BValue::BInt(42L)])), b"l4:spami42ee")
  assert_eq(encode(BValue::BList([])), b"le")
}

test "encode_dict" {
  assert_eq(encode(BValue::BDict([(b"bar", BValue::BStr(b"spam")), (b"foo", BValue::BInt(42L))])), b"d3:bar4:spam3:fooi42ee")
  assert_eq(encode(BValue::BDict([])), b"de")
}

test "encode_nested" {
  let val = BValue::BList([
    BValue::BDict([(b"key", BValue::BList([BValue::BInt(1L), BValue::BInt(2L)]))]),
    BValue::BStr(b"value")
  ])
  assert_eq(encode(val), b"ld3:keyli1ei2eee5:valuee")
}
