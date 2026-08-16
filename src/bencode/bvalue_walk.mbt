///|
/// A small, allocation-conscious walker for arbitrary Bencode trees.
pub(all) struct BValueWalker {
  value : BValue
} derive(Debug)

///|
pub fn BValueWalker::new(value : BValue) -> BValueWalker {
  { value, }
}

///|
pub fn BValueWalker::value(self : BValueWalker) -> BValue {
  self.value
}

///|
fn walk_count(value : BValue, kind : Int) -> Int {
  match value {
    BInt(_) => if kind == 0 { 1 } else { 0 }
    BStr(_) => if kind == 1 { 1 } else { 0 }
    BList(values) => {
      let mut total = if kind == 2 { 1 } else { 0 }
      for item in values {
        total += walk_count(item, kind)
      }
      total
    }
    BDict(values) => {
      let mut total = if kind == 3 { 1 } else { 0 }
      for pair in values {
        total += walk_count(pair.1, kind)
      }
      total
    }
  }
}

///|
pub fn BValueWalker::integer_count(self : BValueWalker) -> Int {
  walk_count(self.value, 0)
}

///|
pub fn BValueWalker::string_count(self : BValueWalker) -> Int {
  walk_count(self.value, 1)
}

///|
pub fn BValueWalker::list_count(self : BValueWalker) -> Int {
  walk_count(self.value, 2)
}

///|
pub fn BValueWalker::dictionary_count(self : BValueWalker) -> Int {
  walk_count(self.value, 3)
}

///|
pub fn BValueWalker::contains_key(self : BValueWalker, key : Bytes) -> Bool {
  match self.value {
    BDict(values) => {
      for pair in values {
        if pair.0 == key || BValueWalker::new(pair.1).contains_key(key) {
          return true
        }
      }
      false
    }
    BList(values) => {
      for item in values {
        if BValueWalker::new(item).contains_key(key) {
          return true
        }
      }
      false
    }
    _ => false
  }
}

///|
pub fn BValueWalker::contains_bytes(
  self : BValueWalker,
  needle : Bytes,
) -> Bool {
  match self.value {
    BStr(value) => value == needle
    BList(values) => {
      for item in values {
        if BValueWalker::new(item).contains_bytes(needle) {
          return true
        }
      }
      false
    }
    BDict(values) => {
      for pair in values {
        if pair.0 == needle || BValueWalker::new(pair.1).contains_bytes(needle) {
          return true
        }
      }
      false
    }
    _ => false
  }
}

///|
pub fn BValueWalker::byte_length(self : BValueWalker) -> Int64 {
  match self.value {
    BInt(_) => 0L
    BStr(value) => value.length().to_int64()
    BList(values) => {
      let mut total = 0L
      for item in values {
        total += BValueWalker::new(item).byte_length()
      }
      total
    }
    BDict(values) => {
      let mut total = 0L
      for pair in values {
        total += pair.0.length().to_int64() +
          BValueWalker::new(pair.1).byte_length()
      }
      total
    }
  }
}

///|
pub fn BValueWalker::max_string_length(self : BValueWalker) -> Int {
  match self.value {
    BStr(value) => value.length()
    BList(values) => {
      let mut result = 0
      for item in values {
        let size = BValueWalker::new(item).max_string_length()
        if size > result {
          result = size
        }
      }
      result
    }
    BDict(values) => {
      let mut result = 0
      for pair in values {
        if pair.0.length() > result {
          result = pair.0.length()
        }
        let size = BValueWalker::new(pair.1).max_string_length()
        if size > result {
          result = size
        }
      }
      result
    }
    _ => 0
  }
}

///|
pub fn BValueWalker::key_count(self : BValueWalker) -> Int {
  match self.value {
    BDict(values) => {
      let mut total = values.length()
      for pair in values {
        total += BValueWalker::new(pair.1).key_count()
      }
      total
    }
    BList(values) => {
      let mut total = 0
      for item in values {
        total += BValueWalker::new(item).key_count()
      }
      total
    }
    _ => 0
  }
}

///|
pub fn BValueWalker::empty_container_count(self : BValueWalker) -> Int {
  match self.value {
    BList(values) => {
      let mut total = if values.length() == 0 { 1 } else { 0 }
      for item in values {
        total += BValueWalker::new(item).empty_container_count()
      }
      total
    }
    BDict(values) => {
      let mut total = if values.length() == 0 { 1 } else { 0 }
      for pair in values {
        total += BValueWalker::new(pair.1).empty_container_count()
      }
      total
    }
    _ => 0
  }
}

///|
pub fn BValueWalker::depth(self : BValueWalker) -> Int {
  match self.value {
    BList(values) => {
      let mut result = 1
      for item in values {
        let depth = BValueWalker::new(item).depth() + 1
        if depth > result {
          result = depth
        }
      }
      result
    }
    BDict(values) => {
      let mut result = 1
      for pair in values {
        let depth = BValueWalker::new(pair.1).depth() + 1
        if depth > result {
          result = depth
        }
      }
      result
    }
    _ => 0
  }
}

///|
pub fn BValueWalker::is_flat(self : BValueWalker) -> Bool {
  self.depth() <= 1
}

///|
pub fn BValueWalker::is_metadata(self : BValueWalker) -> Bool {
  self.dictionary_count() > 0 && self.contains_key(b"info")
}

///|
pub fn BValueWalker::encoded_size(self : BValueWalker) -> Int {
  encode(self.value).length()
}

///|
pub fn BValueWalker::canonical_size(self : BValueWalker) -> Int {
  canonical_bytes(self.value).length()
}

///|
pub fn BValueWalker::canonical(self : BValueWalker) -> BValue {
  canonicalize(self.value)
}

///|
pub fn BValueWalker::round_trip(
  self : BValueWalker,
) -> BValue raise DecodeError {
  canonical_round_trip(self.value)
}
