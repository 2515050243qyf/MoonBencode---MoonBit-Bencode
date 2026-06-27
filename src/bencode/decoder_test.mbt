test "decode_integer" {
  let val = decode(b"i42e")
  assert_eq(val, BValue::BInt(42L))
  let val_neg = decode(b"i-42e")
  assert_eq(val_neg, BValue::BInt(-42L))
  let val_zero = decode(b"i0e")
  assert_eq(val_zero, BValue::BInt(0L))
}

test "decode_string" {
  let val = decode(b"4:spam")
  assert_eq(val, BValue::BStr(b"spam"))
  let val_empty = decode(b"0:")
  assert_eq(val_empty, BValue::BStr(b""))
}

test "decode_list" {
  let val = decode(b"l4:spami42ee")
  assert_eq(val, BValue::BList([BValue::BStr(b"spam"), BValue::BInt(42L)]))
  let val_empty = decode(b"le")
  assert_eq(val_empty, BValue::BList([]))
}

test "decode_dict" {
  let val = decode(b"d3:bar4:spam3:fooi42ee")
  assert_eq(val, BValue::BDict([(b"bar", BValue::BStr(b"spam")), (b"foo", BValue::BInt(42L))]))
  let val_empty = decode(b"de")
  assert_eq(val_empty, BValue::BDict([]))
}

test "decode_nested" {
  // list containing a dict and an int
  let val = decode(b"ld3:bar4:spamei42ee")
  assert_eq(val, BValue::BList([BValue::BDict([(b"bar", BValue::BStr(b"spam"))]), BValue::BInt(42L)]))
}
