///|
/// Formatting-independent conversions useful for JSON adapters and CLIs.
pub fn bytes_equal(a : Bytes, b : Bytes) -> Bool {
  a == b
}

///|
pub fn bytes_length(value : Bytes) -> Int {
  value.length()
}

///|
pub fn bytes_is_empty(value : Bytes) -> Bool {
  value.length() == 0
}

///|
pub fn bytes_prefix_of(prefix : Bytes, value : Bytes) -> Bool {
  if prefix.length() > value.length() {
    false
  } else {
    value.view(start=0, end=prefix.length()).to_owned() == prefix
  }
}

///|
pub fn bytes_suffix_of(suffix : Bytes, value : Bytes) -> Bool {
  if suffix.length() > value.length() {
    false
  } else {
    value
    .view(start=value.length() - suffix.length(), end=value.length())
    .to_owned() ==
    suffix
  }
}

///|
pub fn bytes_contains(value : Bytes, needle : Byte) -> Bool {
  for byte in value {
    if byte == needle {
      return true
    }
  }
  false
}

///|
pub fn bytes_count(value : Bytes, needle : Byte) -> Int {
  let mut result = 0
  for byte in value {
    if byte == needle {
      result += 1
    }
  }
  result
}

///|
pub fn bytes_checksum(value : Bytes) -> UInt {
  let mut result : UInt = 0
  for byte in value {
    result = result + byte.to_int().reinterpret_as_uint()
  }
  result
}

///|
pub fn bytes_xor_checksum(value : Bytes) -> Byte {
  let mut result : Byte = 0
  for byte in value {
    result = result ^ byte
  }
  result
}

///|
pub fn bytes_reverse(value : Bytes) -> Bytes {
  let result : Array[Byte] = []
  for i = value.length() - 1; i >= 0; i = i - 1 {
    result.push(value[i])
  }
  Bytes::from_array(result)
}

///|
pub fn bytes_repeat(value : Byte, count : Int) -> Bytes {
  let result : Array[Byte] = []
  for i = 0; i < count; i = i + 1 {
    result.push(value)
  }
  Bytes::from_array(result)
}

///|
pub fn bytes_concat(values : Array[Bytes]) -> Bytes {
  let result : Array[Byte] = []
  for value in values {
    for byte in value {
      result.push(byte)
    }
  }
  Bytes::from_array(result)
}

///|
pub fn bytes_slice(value : Bytes, start : Int, end : Int) -> Bytes {
  if start < 0 || end < start || end > value.length() {
    b""
  } else {
    value.view(start~, end~).to_owned()
  }
}

///|
pub fn bytes_pad_right(value : Bytes, length : Int, fill : Byte) -> Bytes {
  let result = value.to_array()
  while result.length() < length {
    result.push(fill)
  }
  Bytes::from_array(result)
}

///|
pub fn bytes_pad_left(value : Bytes, length : Int, fill : Byte) -> Bytes {
  let result : Array[Byte] = []
  while result.length() + value.length() < length {
    result.push(fill)
  }
  for byte in value {
    result.push(byte)
  }
  Bytes::from_array(result)
}

///|
pub fn safe_percentage(numerator : Int64, denominator : Int64) -> Int {
  if denominator <= 0L {
    0
  } else if numerator <= 0L {
    0
  } else {
    (numerator * 100L / denominator).to_int()
  }
}

///|
pub fn clamp_int(value : Int, minimum : Int, maximum : Int) -> Int {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
  } else {
    value
  }
}

///|
pub fn clamp_int64(value : Int64, minimum : Int64, maximum : Int64) -> Int64 {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
  } else {
    value
  }
}

///|
pub fn normalize_piece_size(value : Int) -> Int {
  clamp_int(value, 16384, 16777216)
}

///|
pub fn normalize_file_length(value : Int64) -> Int64 {
  if value < 0L {
    0L
  } else {
    value
  }
}
