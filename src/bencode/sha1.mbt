///|
fn rot_l(x : UInt, n : Int) -> UInt {
  (x << n) | (x >> (32 - n))
}

///|
/// Calculates the SHA-1 hash of the given bytes, returning a 20-byte result.
pub fn sha1(data : Bytes) -> Bytes {
  let mut h0 = 0x67452301U
  let mut h1 = 0xEFCDAB89U
  let mut h2 = 0x98BADCFEU
  let mut h3 = 0x10325476U
  let mut h4 = 0xC3D2E1F0U

  let data_arr = data.to_array()
  let orig_len = data_arr.length()
  let mut pad_len = orig_len + 1 + 8
  if pad_len % 64 != 0 {
    pad_len = pad_len + (64 - pad_len % 64)
  }

  let padded = Array::make(pad_len, (0).to_byte())
  for i = 0; i < orig_len; i = i + 1 {
    padded[i] = data_arr[i]
  }
  padded[orig_len] = (0x80).to_byte()

  let len_bits = orig_len.to_int64() * 8L
  padded[pad_len - 8] = (len_bits >> 56).to_int().to_byte()
  padded[pad_len - 7] = (len_bits >> 48).to_int().to_byte()
  padded[pad_len - 6] = (len_bits >> 40).to_int().to_byte()
  padded[pad_len - 5] = (len_bits >> 32).to_int().to_byte()
  padded[pad_len - 4] = (len_bits >> 24).to_int().to_byte()
  padded[pad_len - 3] = (len_bits >> 16).to_int().to_byte()
  padded[pad_len - 2] = (len_bits >> 8).to_int().to_byte()
  padded[pad_len - 1] = len_bits.to_int().to_byte()

  let num_blocks = pad_len / 64
  let w = Array::make(80, 0U)

  for block = 0; block < num_blocks; block = block + 1 {
    let offset = block * 64
    for i = 0; i < 16; i = i + 1 {
      let idx = offset + i * 4
      w[i] = (padded[idx].to_int().reinterpret_as_uint() << 24) |
        (padded[idx + 1].to_int().reinterpret_as_uint() << 16) |
        (padded[idx + 2].to_int().reinterpret_as_uint() << 8) |
        padded[idx + 3].to_int().reinterpret_as_uint()
    }

    for i = 16; i < 80; i = i + 1 {
      w[i] = rot_l(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)
    }

    let mut a = h0
    let mut b = h1
    let mut c = h2
    let mut d = h3
    let mut e = h4

    for i = 0; i < 80; i = i + 1 {
      let (f, k) = if i < 20 {
        ((b & c) | ((b ^ 0xFFFFFFFFU) & d), 0x5A827999U)
      } else if i < 40 {
        (b ^ c ^ d, 0x6ED9EBA1U)
      } else if i < 60 {
        ((b & c) | (b & d) | (c & d), 0x8F1BBCDCU)
      } else {
        (b ^ c ^ d, 0xCA62C1D6U)
      }

      let temp = rot_l(a, 5) + f + e + k + w[i]
      e = d
      d = c
      c = rot_l(b, 30)
      b = a
      a = temp
    }

    h0 = h0 + a
    h1 = h1 + b
    h2 = h2 + c
    h3 = h3 + d
    h4 = h4 + e
  }

  let result = Array::make(20, (0).to_byte())
  fn write_word(buf : Array[Byte], word : UInt, offset : Int) {
    buf[offset] = (word >> 24).reinterpret_as_int().to_byte()
    buf[offset + 1] = (word >> 16).reinterpret_as_int().to_byte()
    buf[offset + 2] = (word >> 8).reinterpret_as_int().to_byte()
    buf[offset + 3] = word.reinterpret_as_int().to_byte()
  }

  write_word(result, h0, 0)
  write_word(result, h1, 4)
  write_word(result, h2, 8)
  write_word(result, h3, 12)
  write_word(result, h4, 16)

  Bytes::from_array(result[:])
}
