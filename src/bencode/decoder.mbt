priv struct Decoder {
  bytes: Bytes
  mut pos: Int
}

fn Decoder::new(bytes: Bytes) -> Decoder {
  { bytes, pos: 0 }
}

fn Decoder::peek(self: Decoder) -> Byte raise DecodeError {
  if self.pos >= self.bytes.length() {
    raise UnexpectedEOF
  }
  self.bytes[self.pos]
}

fn Decoder::advance(self: Decoder) -> Unit {
  self.pos += 1
}

fn Decoder::read_byte(self: Decoder) -> Byte raise DecodeError {
  let b = self.peek()
  self.advance()
  b
}

fn Decoder::parse_int(self: Decoder) -> BValue raise DecodeError {
  self.advance() // skip 'i'
  let mut result : Int64 = 0
  let mut sign : Int64 = 1
  if self.peek() == b'-' {
    sign = -1
    self.advance()
  }
  let mut has_digits = false
  while true {
    let b = self.peek()
    if b >= b'0' && b <= b'9' {
      let digit = (b - b'0').to_int().to_int64()
      result = result * 10 + digit
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
  BInt(result * sign)
}

fn Decoder::parse_string(self: Decoder) -> BValue raise DecodeError {
  let mut len = 0
  let mut has_digits = false
  while true {
    let b = self.peek()
    if b >= b'0' && b <= b'9' {
      len = len * 10 + (b - b'0').to_int()
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
  let arr : Array[Byte] = []
  for i = 0; i < len; i = i + 1 {
    arr.push(self.peek())
    self.advance()
  }
  BStr(Bytes::from_array(arr))
}

fn Decoder::parse_value(self: Decoder) -> BValue raise DecodeError {
  let b = self.peek()
  match b {
    b'i' => self.parse_int()
    b'l' => raise InvalidFormat("List not implemented")
    b'd' => raise InvalidFormat("Dict not implemented")
    b'0'..=b'9' => self.parse_string()
    _ => raise InvalidFormat("Invalid bencode value start")
  }
}

pub fn decode(bytes: Bytes) -> BValue raise DecodeError {
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
