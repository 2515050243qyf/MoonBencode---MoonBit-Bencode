# MoonBencode (Bencode Library for MoonBit)

MoonBencode is a high-performance, mature Bencode serialization and deserialization library written in MoonBit. Bencode is the encoding format used by the BitTorrent peer-to-peer file sharing protocol.

## Features

- **Robust Decoding**: Safely parses `i...e`, `<len>:<string>`, `l...e`, and `d...e` into a MoonBit AST.
- **Accurate Encoding**: Encodes MoonBit AST back to strict Bencode `Bytes` with byte-for-byte fidelity.
- **High Performance**: Highly optimized array and byte sequence operations with zero dependencies.
- **JSON Interoperability**: Supports lossy/lossless conversion of Bencode AST to standard JSON, and parsing JSON back to a canonical, key-sorted Bencode AST.
- **Path Lookup**: Easily retrieves nested list/dictionary values by path.
- **Torrent Info Hash**: Built-in pure MoonBit SHA-1 algorithm to calculate the `info_hash` fingerprint of a torrent file.

- **Typed Torrent Metainfo**: Validates single-file and multi-file torrents,
  canonical piece counts, private flags, tracker tiers, and safe relative paths.
- **File and Piece Planning**: Maps files to piece spans, calculates offsets,
  directory statistics, and produces deterministic download plans.
- **Magnet URI**: Parses and builds normalized v1 Magnet links with display
  names, trackers, exact sources, and keywords.
- **Security and Policy Checks**: Applies resource limits, duplicate-path
  detection, suspicious-name checks, and production-readiness assessments.

## Installation & Dependency Setup

### 1. Add Dependency to Project

Run the following command at the root of your project:

```bash
moon add 2515050243qyf/moon_bencode
```

Or edit your project's `moon.mod` to add the dependency manually:

```json
import {
  "2515050243qyf/moon_bencode" = "0.2.0"
}
```

### 2. Import Package in Module

In the `moon.pkg` file of the package where you wish to use the library, declare the dependency:

```json
{
  "deps": {
    "2515050243qyf/moon_bencode/src/bencode": ""
  }
}
```

## Quick Start

Once configured, call the package functions in your `.mbt` source files using the package alias prefix `@bencode`:

```moonbit
pub fn main raise {
  // Decode a Bencode string
  let val = @bencode.decode(b"d3:bar4:spam3:fooi42ee")
  println("Decoded: \{val}") 
  // Output: BDict([(b"bar", BStr(b"spam")), (b"foo", BInt(42))])
  
  // Encode it back to Bytes
  let bytes = @bencode.encode(val)
  println("Encoded: \{bytes}") 
  // Output: b"d3:bar4:spam3:fooi42ee"
}
```

## Advanced Features

### 1. JSON Interoperability
Convert BValue and BValueView to/from standard Json. The `from_json` method automatically sorts dictionary keys lexicographically to maintain canonical format:
```moonbit
pub fn example_json(val : @bencode.BValue) raise {
  // Convert to Json
  let json_obj = val.to_json()
  println(json_obj.stringify())

  // Parse back to BValue
  let b_val = @bencode.BValue::from_json(json_obj)
}
```

### 2. Path Lookup
Query nested lists and dictionaries using path arrays:
```moonbit
pub fn example_path(torrent : @bencode.BValue) {
  // Retrieve the nested 'name' field inside 'info'
  match torrent.get_path(["info", "name"]) {
    Some(BStr(name)) => println("Name: \{name}")
    _ => println("Not found")
  }
}
```

### 3. Torrent Info Hash Calculation
Calculating the SHA-1 of the `info` dictionary is the core of any BitTorrent client. This is fully supported:
```moonbit
pub fn example_hash(torrent : @bencode.BValue) {
  match torrent.info_hash() {
    Some(hash_bytes) => println("Info Hash: \{hash_bytes}")
    None => println("Invalid torrent")
  }
}
```

## Data Types

The AST represents standard Bencode types using MoonBit Enums:
- `BInt(Int64)`: Bencode integers.
- `BStr(Bytes)`: Bencode byte strings.
- `BList(Array[BValue])`: Bencode lists.
- `BDict(Array[(Bytes, BValue)])`: Bencode dictionaries (keys sorted lexicographically).

## CLI Commands

The following standard commands are available:

- **Run syntax check**: `moon check --deny-warn`
- **Build project**: `moon build`
- **Run tests**: `moon test --deny-warn`
- **Verify code formatting**: `moon fmt --check`

The executable also exposes deterministic workflows over a built-in real-world
Linux distribution fixture:

```bash
moon run cmd/main -- inspect
moon run cmd/main -- validate
moon run cmd/main -- files
moon run cmd/main -- pieces
moon run cmd/main -- magnet
moon run cmd/main -- profile
```

## Reproducible validation

The repository CI uses the latest Moon CLI (currently moonc `0.10.7`) on Linux, macOS, and Windows.
Run the same checks locally from the repository root:

```bash
moon check --deny-warn
moon fmt --check
moon info
moon build
moon test --deny-warn
moon test --deny-warn --target native
```

`moon info` regenerates the public interface files (`pkg.generated.mbti`).
The 0.10.x CLI does not provide an `--deny-warn` option for `moon info`, so
warnings are enforced by `moon check --deny-warn` and `moon test --deny-warn`.

The test suite covers strict integer and string validation, canonical and
duplicate dictionary keys, malformed input, depth limits, zero-copy views,
JSON conversion, nested path lookup, SHA-1 `info_hash`, and a real torrent
metadata sample. It also covers Linux ISO metadata, nested MoonBit source
trees, private torrents, Magnet round trips, piece planning, security policies,
catalog queries, and Bencode structural profiling. Production code is above
4,000 effective MoonBit lines. Coverage can be inspected with:

```bash
moon test --deny-warn --enable-coverage
moon coverage report -f summary
```

## License

Apache-2.0

## Repositories and provenance

- GitHub: https://github.com/2515050243qyf/MoonBencode---MoonBit-Bencode
- GitLink: https://gitlink.org.cn/qyf795201/moon-bencode

This is an original MoonBit implementation of the Bencode and BitTorrent
metainfo APIs. It follows the public BitTorrent metainfo conventions and does
not copy implementation code from an upstream library. Tests use compact,
reproducible metadata fixtures; no torrent payloads or generated build outputs
are redistributed.
