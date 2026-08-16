# Changelog

## 0.2.0

- Added typed torrent metainfo validation and safe multi-file layouts.
- Added piece planning, Magnet URI support, deterministic builders, policy
  assessment, security reports, catalog queries, and structural profiling.
- Added reproducible CLI workflows and a stricter three-platform acceptance CI.

## 0.1.3

- Documented the complete cross-platform acceptance workflow and pinned CI
  to a reproducible MoonBit 0.10.x toolchain.

## 0.1.2

- Added strict Bencode validation for integer overflow, leading zeros, key
  ordering, duplicate keys, malformed lengths, and nesting depth.
- Added zero-copy decoding views, JSON conversion, path lookup, and pure
  MoonBit SHA-1 `info_hash` support.
- Added cross-platform CI with formatting, interface generation, build,
  regular tests, and native tests.

## 1.0.0

- Initial public release of the MoonBencode library.
