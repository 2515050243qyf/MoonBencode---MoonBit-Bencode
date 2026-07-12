# MoonBencode (MoonBit Bencode)

MoonBencode is a high-performance, mature bencode serialization and deserialization library written in MoonBit. Bencode is the encoding format used by the BitTorrent peer-to-peer file sharing protocol.

## Features

- **Robust Decoding**: Safely parses `i...e`, `<len>:<string>`, `l...e`, and `d...e` into a MoonBit AST.
- **Accurate Encoding**: Encodes MoonBit AST back to strict Bencode `Bytes` with byte-for-byte fidelity.
- **High Performance**: Highly optimized array byte slices and zero dependencies.
- **Mature Ecosystem**: Supports all standard Bencode features without external libraries.

## Installation

Add the library to your `moon.pkg.json`:

```json
{
  "deps": {
    "2515050243qyf/moon_bencode": "0.1.1"
  }
}
```

## Quick Start

```moonbit nocheck
import "2515050243qyf/moon_bencode/src/bencode"

pub fn main raise {
  // Decode a Bencode string
  let val = bencode::decode(b"d3:bar4:spam3:fooi42ee")
  println("Decoded: \{val}") 
  // Output: BDict([(b"bar", BStr(b"spam")), (b"foo", BInt(42))])
  
  // Encode it back to Bytes
  let bytes = bencode::encode(val)
  println("Encoded: \{bytes}") 
  // Output: b"d3:bar4:spam3:fooi42ee"
}
```

## Data Types

The AST represents standard Bencode types using MoonBit Enums:
- `BInt(Int64)`: Bencode integers.
- `BStr(Bytes)`: Bencode byte strings.
- `BList(Array[BValue])`: Bencode lists.
- `BDict(Array[(Bytes, BValue)])`: Bencode dictionaries.

## License

Apache-2.0
