/// Encoder is a fast, array-backed buffer for Bencode serialization.
/// By writing directly into an Array[Byte], we avoid costly string concatenations.
priv struct Encoder {
  arr: Array[Byte]
}

/// Creates a new encoder with an empty byte array.
fn Encoder::new() -> Encoder {
  { arr: [] }
}

/// Writes a single byte to the output buffer.
fn Encoder::write_byte(self: Encoder, b: Byte) -> Unit {
  self.arr.push(b)
}

/// Writes multiple bytes sequentially to the output buffer.
fn Encoder::write_bytes(self: Encoder, bytes: Bytes) -> Unit {
  for i = 0; i < bytes.length(); i = i + 1 {
    self.arr.push(bytes[i])
  }
}

fn Encoder::write_string_ascii(self: Encoder, s: String) -> Unit {
  for i = 0; i < s.length(); i = i + 1 {
    self.write_byte(s[i].to_int().to_byte())
  }
}

fn Encoder::encode_value(self: Encoder, val: BValue) -> Unit {
  match val {
    BInt(i) => {
      self.write_byte(b'i')
      self.write_string_ascii(i.to_string())
      self.write_byte(b'e')
    }
    BStr(bytes) => {
      self.write_string_ascii(bytes.length().to_string())
      self.write_byte(b':')
      self.write_bytes(bytes)
    }
    BList(list) => {
      self.write_byte(b'l')
      for i = 0; i < list.length(); i = i + 1 {
        self.encode_value(list[i])
      }
      self.write_byte(b'e')
    }
    BDict(dict) => {
      self.write_byte(b'd')
      for i = 0; i < dict.length(); i = i + 1 {
        let (key, v) = dict[i]
        self.encode_value(BStr(key))
        self.encode_value(v)
      }
      self.write_byte(b'e')
    }
  }
}

/// Encodes a BValue AST into a standard Bencode Bytes stream.
/// Returns a byte-for-byte exact representation suitable for hashing.
pub fn encode(val: BValue) -> Bytes {
  let encoder = Encoder::new()
  encoder.encode_value(val)
  Bytes::from_array(encoder.arr)
}
