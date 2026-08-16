///|
/// Pure transformations for applications that need to rewrite metainfo.
fn replace_field(
  fields : Array[(Bytes, BValue)],
  key : Bytes,
  value : BValue,
) -> Array[(Bytes, BValue)] {
  let result : Array[(Bytes, BValue)] = []
  let mut replaced = false
  for pair in fields {
    if pair.0 == key {
      result.push((key, value))
      replaced = true
    } else {
      result.push(pair)
    }
  }
  if !replaced {
    result.push((key, value))
  }
  result
}

///|
fn remove_field(
  fields : Array[(Bytes, BValue)],
  key : Bytes,
) -> Array[(Bytes, BValue)] {
  let result : Array[(Bytes, BValue)] = []
  for pair in fields {
    if pair.0 != key {
      result.push(pair)
    }
  }
  result
}

///|
fn map_info(
  value : BValue,
  transform : (Array[(Bytes, BValue)]) -> Array[(Bytes, BValue)],
) -> BValue raise TorrentError {
  match value {
    BDict(root) =>
      match dict_lookup(root, b"info") {
        Some(BDict(info)) =>
          BDict(replace_field(root, b"info", BDict(transform(info))))
        Some(_) => raise InvalidMetadata("info must be a dictionary")
        None => raise MissingField(b"info")
      }
    _ => raise InvalidMetadata("torrent root must be a dictionary")
  }
}

///|
pub fn rename_torrent(
  value : BValue,
  name : Bytes,
) -> BValue raise TorrentError {
  map_info(value, fn(info) { replace_field(info, b"name", BStr(name)) })
}

///|
pub fn set_private(value : BValue, private : Bool) -> BValue raise TorrentError {
  map_info(value, fn(info) {
    if private {
      replace_field(info, b"private", BInt(1L))
    } else {
      remove_field(info, b"private")
    }
  })
}

///|
pub fn remove_tracker(value : BValue, tracker : Bytes) -> BValue {
  match value {
    BDict(root) => {
      let result : Array[(Bytes, BValue)] = []
      for pair in root {
        if pair.0 == b"announce" && pair.1 == BStr(tracker) {
          ()
        } else if pair.0 == b"announce-list" {
          match pair.1 {
            BList(tiers) => {
              let new_tiers : Array[BValue] = []
              for tier in tiers {
                match tier {
                  BList(urls) => {
                    let kept : Array[BValue] = []
                    for url in urls {
                      if url != BStr(tracker) {
                        kept.push(url)
                      }
                    }
                    if kept.length() > 0 {
                      new_tiers.push(BList(kept))
                    }
                  }
                  _ => new_tiers.push(tier)
                }
              }
              if new_tiers.length() > 0 {
                result.push((pair.0, BList(new_tiers)))
              }
            }
            _ => result.push(pair)
          }
        } else {
          result.push(pair)
        }
      }
      BDict(result)
    }
    _ => value
  }
}

///|
pub fn add_tracker(value : BValue, tracker : Bytes) -> BValue {
  match value {
    BDict(root) => {
      let result = root.copy()
      let mut found = false
      for i = 0; i < result.length(); i = i + 1 {
        if result[i].0 == b"announce" {
          found = true
        }
      }
      if !found {
        result.push((b"announce", BStr(tracker)))
      }
      BDict(result)
    }
    _ => value
  }
}

///|
pub fn canonicalize(value : BValue) -> BValue {
  match value {
    BInt(_) | BStr(_) => value
    BList(values) => BList(values.map(fn(item) { canonicalize(item) }))
    BDict(values) => {
      let result : Array[(Bytes, BValue)] = []
      for pair in values {
        result.push((pair.0, canonicalize(pair.1)))
      }
      result.sort_by(fn(a, b) {
        if a.0 < b.0 {
          -1
        } else if a.0 > b.0 {
          1
        } else {
          0
        }
      })
      BDict(result)
    }
  }
}

///|
pub fn canonical_bytes(value : BValue) -> Bytes {
  encode(canonicalize(value))
}

///|
pub fn canonical_round_trip(value : BValue) -> BValue raise DecodeError {
  decode(canonical_bytes(value))
}

///|
pub fn has_field(value : BValue, key : Bytes) -> Bool {
  match value {
    BDict(fields) => dict_lookup(fields, key) is Some(_)
    _ => false
  }
}

///|
pub fn field_bytes(value : BValue, key : Bytes) -> Bytes? {
  match value {
    BDict(fields) =>
      match dict_lookup(fields, key) {
        Some(BStr(bytes)) => Some(bytes)
        _ => None
      }
    _ => None
  }
}

///|
pub fn field_int(value : BValue, key : Bytes) -> Int64? {
  match value {
    BDict(fields) =>
      match dict_lookup(fields, key) {
        Some(BInt(number)) => Some(number)
        _ => None
      }
    _ => None
  }
}
