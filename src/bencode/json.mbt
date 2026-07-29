///|
pub suberror JsonConversionError {
  UnsupportedJsonNull
} derive(Eq, Debug)

///|
pub impl Show for JsonConversionError with fn output(self, logger) {
  match self {
    UnsupportedJsonNull =>
      logger.write_string("Unsupported JSON Null value in Bencode")
  }
}

///|
/// Converts a BValue to a standard Json representation.
pub fn BValue::to_json(self : BValue) -> Json {
  match self {
    BInt(val) => Json::number(val.to_double(), repr=val.to_string())
    BStr(bytes) => Json::string(@utf8.decode_lossy(bytes.view()))
    BList(list) => Json::array(list.map(fn(v) { v.to_json() }))
    BDict(dict) => {
      let map = Map([])
      for kv in dict {
        let key_str = @utf8.decode_lossy(kv.0.view())
        map.set(key_str, kv.1.to_json())
      }
      Json::object(map)
    }
  }
}

///|
/// Converts a BValueView to a standard Json representation.
pub fn BValueView::to_json(self : BValueView) -> Json {
  match self {
    BInt(val) => Json::number(val.to_double(), repr=val.to_string())
    BStr(view) => Json::string(@utf8.decode_lossy(view))
    BList(list) => Json::array(list.map(fn(v) { v.to_json() }))
    BDict(dict) => {
      let map = Map([])
      for kv in dict {
        let key_str = @utf8.decode_lossy(kv.0)
        map.set(key_str, kv.1.to_json())
      }
      Json::object(map)
    }
  }
}

///|
/// Helper function to parse standard Json back to a BValue.
/// Ensures all Bencode dictionary keys are sorted lexicographically.
pub fn BValue::from_json(json : Json) -> BValue raise JsonConversionError {
  match json {
    Null => raise UnsupportedJsonNull
    True => BInt(1L)
    False => BInt(0L)
    Number(d, repr~) =>
      match repr {
        Some(s) =>
          try {
            let val : Int64 = @strconv.from_str(s[:])
            BInt(val)
          } catch {
            _ => BInt(d.to_int64())
          }
        None => BInt(d.to_int64())
      }
    String(s) => BStr(@utf8.encode(s))
    Array(arr) => {
      let list = Array::new(capacity=arr.length())
      for item in arr {
        list.push(BValue::from_json(item))
      }
      BList(list)
    }
    Object(obj) => {
      let dict = Array::new(capacity=obj.length())
      for k, v in obj {
        let k_bytes = @utf8.encode(k)
        let v_val = BValue::from_json(v)
        dict.push((k_bytes, v_val))
      }
      dict.sort_by(fn(a, b) { bytes_compare(a.0, b.0) })
      BDict(dict)
    }
  }
}
