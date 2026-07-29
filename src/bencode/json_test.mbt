///|
test "bencode_to_json" {
  let b_int = BValue::BInt(42L)
  let b_str = BValue::BStr(b"hello")
  let b_list = BValue::BList([BInt(1L), BStr(b"two")])
  let b_dict = BValue::BDict([(b"a", BInt(10L)), (b"b", BStr(b"val"))])

  inspect(b_int.to_json().stringify(), content="42")
  inspect(b_str.to_json().stringify(), content="\"hello\"")
  inspect(b_list.to_json().stringify(), content="[1,\"two\"]")
  inspect(b_dict.to_json().stringify(), content="{\"a\":10,\"b\":\"val\"}")
}

///|
test "json_to_bencode" {
  let j_int = Json::number(42.0, repr="42")
  let j_str = Json::string("hello")
  let j_list = Json::array([Json::number(1.0, repr="1"), Json::string("two")])

  let map = Map([])
  map.set("b", Json::string("val"))
  map.set("a", Json::number(10.0, repr="10"))
  let j_dict = Json::object(map)

  try {
    let b_int = BValue::from_json(j_int)
    let b_str = BValue::from_json(j_str)
    let b_list = BValue::from_json(j_list)
    let b_dict = BValue::from_json(j_dict)

    assert_eq(b_int, BValue::BInt(42L))
    assert_eq(b_str, BValue::BStr(b"hello"))
    assert_eq(b_list, BValue::BList([BInt(1L), BStr(b"two")]))
    // Test that the dictionary keys were sorted lexicographically during from_json conversion!
    assert_eq(b_dict, BValue::BDict([(b"a", BInt(10L)), (b"b", BStr(b"val"))]))
  } catch {
    _ => fail("JSON to Bencode conversion failed")
  }
}
