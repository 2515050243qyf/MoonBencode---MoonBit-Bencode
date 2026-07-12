///|
/// Decoder is a stateful cursor over a byte array used for parsing Bencode data.
priv struct Decoder {
  bytes : Bytes
  mut pos : Int
  mut depth : Int
  max_depth : Int
}

///|
/// Helper function to compare two Bytes lexicographically.
fn bytes_compare(a : Bytes, b : Bytes) -> Int {
  let len_a = a.length()
  let len_b = b.length()
  let min_len = if len_a < len_b { len_a } else { len_b }
  for i = 0; i < min_len; i = i + 1 {
    let byte_a = a[i]
    let byte_b = b[i]
    if byte_a < byte_b {
      return -1
    } else if byte_a > byte_b {
      return 1
    }
  }
  if len_a < len_b {
    -1
  } else if len_a > len_b {
    1
  } else {
    0
  }
}

///|
/// Helper function to compare two BytesView lexicographically.
fn bytes_view_compare(a : BytesView, b : BytesView) -> Int {
  let len_a = a.length()
  let len_b = b.length()
  let min_len = if len_a < len_b { len_a } else { len_b }
  for i = 0; i < min_len; i = i + 1 {
    let byte_a = a[i]
    let byte_b = b[i]
    if byte_a < byte_b {
      return -1
    } else if byte_a > byte_b {
      return 1
    }
  }
  if len_a < len_b {
    -1
  } else if len_a > len_b {
    1
  } else {
    0
  }
}

///|
/// Creates a new decoder instance initialized at the beginning of the byte array.
fn Decoder::new(bytes : Bytes) -> Decoder {
  { bytes, pos: 0, depth: 0, max_depth: 1000 }
}

///|
/// Peeks at the current byte without advancing the cursor.
/// Raises UnexpectedEOF if the cursor is at or past the end of the byte array.
fn Decoder::peek(self : Decoder) -> Byte raise DecodeError {
  if self.pos >= self.bytes.length() {
    raise UnexpectedEOF
  }
  self.bytes[self.pos]
}

///|
/// Advances the cursor by one byte.
fn Decoder::advance(self : Decoder) -> Unit {
  self.pos += 1
}

///|
/// Decodes a Bencode encoded byte array into a BValue AST.
/// Raises a DecodeError if the format is invalid or if there are trailing bytes.
pub fn decode(bytes : Bytes) -> BValue raise DecodeError {
  if bytes.length() == 0 {
    raise UnexpectedEOF
  }
  let decoder = Decoder::new(bytes)
  let val = decoder.parse_value()
  if decoder.pos < decoder.bytes.length() {
    raise InvalidFormat("Trailing garbage after valid bencode")
  }
  val
}

///|
/// Decodes a Bencode encoded byte array into a zero-copy BValueView AST.
/// Raises a DecodeError if the format is invalid or if there are trailing bytes.
pub fn decode_view(bytes : Bytes) -> BValueView raise DecodeError {
  if bytes.length() == 0 {
    raise UnexpectedEOF
  }
  let decoder = Decoder::new(bytes)
  let val = decoder.parse_value_view()
  if decoder.pos < decoder.bytes.length() {
    raise InvalidFormat("Trailing garbage after valid bencode")
  }
  val
}

///|
fn Decoder::incr_depth(self : Decoder) -> Unit raise DecodeError {
  self.depth += 1
  if self.depth > self.max_depth {
    raise InvalidFormat("Nesting depth limit exceeded")
  }
}

///|
fn Decoder::decr_depth(self : Decoder) -> Unit {
  self.depth -= 1
}

///|
fn Decoder::parse_int_raw(self : Decoder) -> Int64 raise DecodeError {
  self.advance() // skip 'i'
  let mut result : Int64 = 0
  let mut sign : Int64 = 1
  if self.peek() == b'-' {
    sign = -1
    self.advance()
  }
  let first_byte = self.peek()
  if first_byte == b'0' {
    self.advance()
    if self.peek() != b'e' {
      raise InvalidFormat("Integer has leading zeros")
    }
    if sign == -1 {
      raise InvalidFormat("Negative zero is invalid")
    }
    self.advance() // skip 'e'
    return 0L
  }
  let mut has_digits = false
  let limit = 922337203685477580L
  while true {
    let b = self.peek()
    if b >= b'0' && b <= b'9' {
      let digit = (b - b'0').to_int().to_int64()
      // Check for overflow
      if result > limit {
        raise InvalidFormat("Integer overflow")
      }
      if result == limit {
        if sign == 1L && digit > 7L {
          raise InvalidFormat("Integer overflow")
        }
        if sign == -1L && digit > 8L {
          raise InvalidFormat("Integer overflow")
        }
      }
      result = result * 10L + digit
      has_digits = true
      self.advance()
    } else if b == b'e' {
      if !has_digits {
        raise InvalidFormat("Empty integer")
      }
      self.advance()
      break
    } else {
      raise InvalidFormat("Invalid character in integer")
    }
  }
  result * sign
}

///|
fn Decoder::parse_int(self : Decoder) -> BValue raise DecodeError {
  BInt(self.parse_int_raw())
}

///|
fn Decoder::parse_string_len(self : Decoder) -> Int raise DecodeError {
  let first_byte = self.peek()
  if first_byte == b'0' {
    self.advance()
    if self.peek() != b':' {
      raise InvalidFormat("String length has leading zeros")
    }
    self.advance() // skip ':'
    return 0
  }
  let mut len = 0
  let mut has_digits = false
  while true {
    let b = self.peek()
    if b >= b'0' && b <= b'9' {
      let digit = (b - b'0').to_int()
      // Prevent overflow
      if len > 214748364 {
        raise InvalidFormat("String length overflow")
      }
      if len == 214748364 && digit > 7 {
        raise InvalidFormat("String length overflow")
      }
      len = len * 10 + digit
      has_digits = true
      self.advance()
    } else if b == b':' {
      if !has_digits {
        raise InvalidFormat("Empty string length")
      }
      self.advance()
      break
    } else {
      raise InvalidFormat("Invalid character in string length")
    }
  }
  len
}

///|
fn Decoder::parse_string(self : Decoder) -> BValue raise DecodeError {
  let len = self.parse_string_len()
  if self.pos + len > self.bytes.length() {
    raise UnexpectedEOF
  }
  let view = self.bytes.view(start=self.pos, end=self.pos + len)
  self.pos += len
  BStr(view.to_owned())
}

///|
fn Decoder::parse_string_view(self : Decoder) -> BValueView raise DecodeError {
  let len = self.parse_string_len()
  if self.pos + len > self.bytes.length() {
    raise UnexpectedEOF
  }
  let view = self.bytes.view(start=self.pos, end=self.pos + len)
  self.pos += len
  BStr(view)
}

///|
fn Decoder::parse_list(self : Decoder) -> BValue raise DecodeError {
  self.incr_depth()
  self.advance() // skip 'l'
  let list : Array[BValue] = []
  while true {
    let b = self.peek()
    if b == b'e' {
      self.advance()
      break
    }
    let val = self.parse_value()
    list.push(val)
  }
  self.decr_depth()
  BList(list)
}

///|
fn Decoder::parse_list_view(self : Decoder) -> BValueView raise DecodeError {
  self.incr_depth()
  self.advance() // skip 'l'
  let list : Array[BValueView] = []
  while true {
    let b = self.peek()
    if b == b'e' {
      self.advance()
      break
    }
    let val = self.parse_value_view()
    list.push(val)
  }
  self.decr_depth()
  BList(list)
}

///|
fn Decoder::parse_dict(self : Decoder) -> BValue raise DecodeError {
  self.incr_depth()
  self.advance() // skip 'd'
  let dict : Array[(Bytes, BValue)] = []
  let mut last_key : Bytes? = None
  while true {
    let b = self.peek()
    if b == b'e' {
      self.advance()
      break
    }
    let key_val = self.parse_string()
    match key_val {
      BStr(key) => {
        match last_key {
          Some(prev) => {
            let cmp = bytes_compare(key, prev)
            if cmp < 0 {
              raise InvalidFormat(
                "Dictionary keys are not sorted lexicographically",
              )
            } else if cmp == 0 {
              raise InvalidFormat("Dictionary contains duplicate keys")
            }
          }
          None => ()
        }
        last_key = Some(key)
        let val = self.parse_value()
        dict.push((key, val))
      }
      _ => raise InvalidFormat("Dict key must be a string")
    }
  }
  self.decr_depth()
  BDict(dict)
}

///|
fn Decoder::parse_dict_view(self : Decoder) -> BValueView raise DecodeError {
  self.incr_depth()
  self.advance() // skip 'd'
  let dict : Array[(BytesView, BValueView)] = []
  let mut last_key : BytesView? = None
  while true {
    let b = self.peek()
    if b == b'e' {
      self.advance()
      break
    }
    let key_val = self.parse_string_view()
    match key_val {
      BStr(key) => {
        match last_key {
          Some(prev) => {
            let cmp = bytes_view_compare(key, prev)
            if cmp < 0 {
              raise InvalidFormat(
                "Dictionary keys are not sorted lexicographically",
              )
            } else if cmp == 0 {
              raise InvalidFormat("Dictionary contains duplicate keys")
            }
          }
          None => ()
        }
        last_key = Some(key)
        let val = self.parse_value_view()
        dict.push((key, val))
      }
      _ => raise InvalidFormat("Dict key must be a string")
    }
  }
  self.decr_depth()
  BDict(dict)
}

///|
fn Decoder::parse_value(self : Decoder) -> BValue raise DecodeError {
  let b = self.peek()
  match b {
    b'i' => self.parse_int()
    b'l' => self.parse_list()
    b'd' => self.parse_dict()
    b'0'..=b'9' => self.parse_string()
    _ => raise InvalidFormat("Invalid bencode value start")
  }
}

///|
fn Decoder::parse_value_view(self : Decoder) -> BValueView raise DecodeError {
  let b = self.peek()
  match b {
    b'i' => BInt(self.parse_int_raw())
    b'l' => self.parse_list_view()
    b'd' => self.parse_dict_view()
    b'0'..=b'9' => self.parse_string_view()
    _ => raise InvalidFormat("Invalid bencode value start")
  }
}
