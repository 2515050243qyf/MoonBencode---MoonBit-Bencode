///|
/// Retrieves a nested value in a BValue AST using a path of strings.
/// If a path element is a digit, it is treated as a list index.
pub fn BValue::get_path(self : BValue, path : Array[String]) -> BValue? {
  let mut current = self
  for key in path {
    match current {
      BList(list) =>
        try {
          let idx : Int = @strconv.from_str(key[:])
          if idx >= 0 && idx < list.length() {
            current = list[idx]
          } else {
            return None
          }
        } catch {
          _ => return None
        }
      BDict(dict) => {
        let key_bytes = @utf8.encode(key)
        let mut found = false
        for kv in dict {
          if kv.0 == key_bytes {
            current = kv.1
            found = true
            break
          }
        }
        if !found {
          return None
        }
      }
      _ => return None
    }
  }
  Some(current)
}

///|
/// Retrieves a nested value in a BValueView AST using a path of strings.
/// If a path element is a digit, it is treated as a list index.
pub fn BValueView::get_path(
  self : BValueView,
  path : Array[String],
) -> BValueView? {
  let mut current = self
  for key in path {
    match current {
      BList(list) =>
        try {
          let idx : Int = @strconv.from_str(key[:])
          if idx >= 0 && idx < list.length() {
            current = list[idx]
          } else {
            return None
          }
        } catch {
          _ => return None
        }
      BDict(dict) => {
        let key_bytes = @utf8.encode(key)
        let mut found = false
        for kv in dict {
          if bytes_view_equals_bytes(kv.0, key_bytes) {
            current = kv.1
            found = true
            break
          }
        }
        if !found {
          return None
        }
      }
      _ => return None
    }
  }
  Some(current)
}

///|
fn bytes_view_equals_bytes(view : BytesView, bytes : Bytes) -> Bool {
  if view.length() != bytes.length() {
    return false
  }
  for i = 0; i < view.length(); i = i + 1 {
    if view[i] != bytes[i] {
      return false
    }
  }
  true
}
