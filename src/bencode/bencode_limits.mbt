///|
/// Resource limits for decoding untrusted Bencode payloads.
pub(all) struct DecodeLimits {
  max_depth : Int
  max_string_length : Int
  max_container_length : Int
  max_total_bytes : Int
} derive(Eq, Debug)

///|
pub fn DecodeLimits::default() -> DecodeLimits {
  {
    max_depth: 1000,
    max_string_length: 268435456,
    max_container_length: 1000000,
    max_total_bytes: 536870912,
  }
}

///|
pub fn DecodeLimits::small() -> DecodeLimits {
  {
    max_depth: 64,
    max_string_length: 1048576,
    max_container_length: 10000,
    max_total_bytes: 16777216,
  }
}

///|
pub fn DecodeLimits::with_depth(
  self : DecodeLimits,
  value : Int,
) -> DecodeLimits {
  { ..self, max_depth: value }
}

///|
pub fn DecodeLimits::with_string_limit(
  self : DecodeLimits,
  value : Int,
) -> DecodeLimits {
  { ..self, max_string_length: value }
}

///|
pub fn DecodeLimits::with_container_limit(
  self : DecodeLimits,
  value : Int,
) -> DecodeLimits {
  { ..self, max_container_length: value }
}

///|
pub fn DecodeLimits::with_total_limit(
  self : DecodeLimits,
  value : Int,
) -> DecodeLimits {
  { ..self, max_total_bytes: value }
}

///|
pub fn DecodeLimits::allows_depth(self : DecodeLimits, value : Int) -> Bool {
  value <= self.max_depth
}

///|
pub fn DecodeLimits::allows_string(self : DecodeLimits, value : Int) -> Bool {
  value <= self.max_string_length
}

///|
pub fn DecodeLimits::allows_container(self : DecodeLimits, value : Int) -> Bool {
  value <= self.max_container_length
}

///|
pub fn DecodeLimits::allows_total(self : DecodeLimits, value : Int) -> Bool {
  value <= self.max_total_bytes
}

///|
pub fn DecodeLimits::is_stricter_than(
  self : DecodeLimits,
  other : DecodeLimits,
) -> Bool {
  self.max_depth <= other.max_depth &&
  self.max_string_length <= other.max_string_length &&
  self.max_container_length <= other.max_container_length &&
  self.max_total_bytes <= other.max_total_bytes
}

///|
pub fn DecodeLimits::is_unbounded(self : DecodeLimits) -> Bool {
  self.max_depth >= 1000000 &&
  self.max_string_length >= 2147483647 &&
  self.max_container_length >= 2147483647
}

///|
pub fn DecodeLimits::minimum(
  self : DecodeLimits,
  other : DecodeLimits,
) -> DecodeLimits {
  {
    max_depth: if self.max_depth < other.max_depth {
      self.max_depth
    } else {
      other.max_depth
    },
    max_string_length: if self.max_string_length < other.max_string_length {
      self.max_string_length
    } else {
      other.max_string_length
    },
    max_container_length: if self.max_container_length <
      other.max_container_length {
      self.max_container_length
    } else {
      other.max_container_length
    },
    max_total_bytes: if self.max_total_bytes < other.max_total_bytes {
      self.max_total_bytes
    } else {
      other.max_total_bytes
    },
  }
}

///|
pub fn DecodeLimits::maximum(
  self : DecodeLimits,
  other : DecodeLimits,
) -> DecodeLimits {
  {
    max_depth: if self.max_depth > other.max_depth {
      self.max_depth
    } else {
      other.max_depth
    },
    max_string_length: if self.max_string_length > other.max_string_length {
      self.max_string_length
    } else {
      other.max_string_length
    },
    max_container_length: if self.max_container_length >
      other.max_container_length {
      self.max_container_length
    } else {
      other.max_container_length
    },
    max_total_bytes: if self.max_total_bytes > other.max_total_bytes {
      self.max_total_bytes
    } else {
      other.max_total_bytes
    },
  }
}
