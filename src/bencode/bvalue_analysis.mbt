///|
/// Structural statistics for arbitrary Bencode values.
pub(all) struct BValueProfile {
  mut integers : Int
  mut strings : Int
  mut lists : Int
  mut dictionaries : Int
  mut total_bytes : Int64
  mut max_depth : Int
  mut keys : Int
  mut leaves : Int
  mut empty_values : Int
} derive(Eq, Debug)

///|
pub fn BValueProfile::empty() -> BValueProfile {
  {
    integers: 0,
    strings: 0,
    lists: 0,
    dictionaries: 0,
    total_bytes: 0L,
    max_depth: 0,
    keys: 0,
    leaves: 0,
    empty_values: 0,
  }
}

///|
fn profile_value(value : BValue, depth : Int, profile : BValueProfile) -> Unit {
  if depth > profile.max_depth {
    profile.max_depth = depth
  }
  match value {
    BInt(_) => {
      profile.integers += 1
      profile.leaves += 1
    }
    BStr(bytes) => {
      profile.strings += 1
      profile.total_bytes += bytes.length().to_int64()
      profile.leaves += 1
      if bytes.length() == 0 {
        profile.empty_values += 1
      }
    }
    BList(values) => {
      profile.lists += 1
      if values.length() == 0 {
        profile.empty_values += 1
      }
      for value in values {
        profile_value(value, depth + 1, profile)
      }
    }
    BDict(values) => {
      profile.dictionaries += 1
      profile.keys += values.length()
      if values.length() == 0 {
        profile.empty_values += 1
      }
      for pair in values {
        profile.total_bytes += pair.0.length().to_int64()
        profile_value(pair.1, depth + 1, profile)
      }
    }
  }
}

///|
pub fn profile(value : BValue) -> BValueProfile {
  let result = BValueProfile::empty()
  profile_value(value, 0, result)
  result
}

///|
pub fn BValueProfile::container_count(self : BValueProfile) -> Int {
  self.lists + self.dictionaries
}

///|
pub fn BValueProfile::leaf_count(self : BValueProfile) -> Int {
  self.leaves
}

///|
pub fn BValueProfile::value_count(self : BValueProfile) -> Int {
  self.integers + self.strings + self.lists + self.dictionaries
}

///|
pub fn BValueProfile::is_scalar(self : BValueProfile) -> Bool {
  self.container_count() == 0
}

///|
pub fn BValueProfile::is_deep(self : BValueProfile, threshold : Int) -> Bool {
  self.max_depth >= threshold
}

///|
pub fn BValueProfile::is_binary_heavy(
  self : BValueProfile,
  threshold : Int64,
) -> Bool {
  self.total_bytes >= threshold
}

///|
pub fn BValueProfile::empty_ratio(self : BValueProfile) -> Int {
  if self.value_count() == 0 {
    0
  } else {
    self.empty_values * 100 / self.value_count()
  }
}

///|
pub fn BValueProfile::integer_ratio(self : BValueProfile) -> Int {
  if self.value_count() == 0 {
    0
  } else {
    self.integers * 100 / self.value_count()
  }
}

///|
pub fn BValueProfile::string_ratio(self : BValueProfile) -> Int {
  if self.value_count() == 0 {
    0
  } else {
    self.strings * 100 / self.value_count()
  }
}

///|
pub fn BValueProfile::dictionary_ratio(self : BValueProfile) -> Int {
  if self.value_count() == 0 {
    0
  } else {
    self.dictionaries * 100 / self.value_count()
  }
}

///|
pub fn BValueProfile::same_shape(
  self : BValueProfile,
  other : BValueProfile,
) -> Bool {
  self.integers == other.integers &&
  self.strings == other.strings &&
  self.lists == other.lists &&
  self.dictionaries == other.dictionaries &&
  self.max_depth == other.max_depth
}

///|
pub fn BValueProfile::merge(
  self : BValueProfile,
  other : BValueProfile,
) -> BValueProfile {
  {
    integers: self.integers + other.integers,
    strings: self.strings + other.strings,
    lists: self.lists + other.lists,
    dictionaries: self.dictionaries + other.dictionaries,
    total_bytes: self.total_bytes + other.total_bytes,
    max_depth: if self.max_depth > other.max_depth {
      self.max_depth
    } else {
      other.max_depth
    },
    keys: self.keys + other.keys,
    leaves: self.leaves + other.leaves,
    empty_values: self.empty_values + other.empty_values,
  }
}

///|
pub fn BValueProfile::complexity(self : BValueProfile) -> Bytes {
  if self.max_depth > 32 || self.value_count() > 10000 {
    b"high"
  } else if self.max_depth > 8 || self.value_count() > 100 {
    b"medium"
  } else {
    b"low"
  }
}

///|
pub fn BValueProfile::payload_density(self : BValueProfile) -> Int {
  if self.value_count() == 0 {
    0
  } else {
    (self.total_bytes / self.value_count().to_int64()).to_int()
  }
}

///|
pub fn BValueProfile::has_lists(self : BValueProfile) -> Bool {
  self.lists > 0
}

///|
pub fn BValueProfile::has_dictionaries(self : BValueProfile) -> Bool {
  self.dictionaries > 0
}

///|
pub fn BValueProfile::is_metadata_like(self : BValueProfile) -> Bool {
  self.dictionaries > 0 && self.keys >= self.strings
}
