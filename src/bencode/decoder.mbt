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

fn Decoder::parse_value(self: Decoder) -> BValue raise DecodeError {
  let b = self.peek()
  match b {
    b'i' => raise InvalidFormat("Integer not implemented")
    b'l' => raise InvalidFormat("List not implemented")
    b'd' => raise InvalidFormat("Dict not implemented")
    b'0'..=b'9' => raise InvalidFormat("String not implemented")
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
