///|
fn main raise {
  // Decode a Bencode string
  let val = @bencode.decode(b"d3:bar4:spam3:fooi42ee")
  println("Decoded successfully")

  // Encode it back to Bytes
  let bytes = @bencode.encode(val)
  println("Encoded back length: \{bytes.length()}")
}
