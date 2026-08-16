# MoonBencode Torrent Toolkit Design

## Goal

Extend MoonBencode from a codec into a reusable BitTorrent metainfo toolkit
without breaking the existing `BValue`/`BValueView` API. The extension must
provide practical torrent inspection, validation, magnet-link handling, file
layout analysis, and deterministic piece planning for MoonBit applications.

## Boundaries

The library owns pure metainfo parsing and analysis. It does not open network
sockets, contact trackers, or implement peer wire protocol behavior. This keeps
the package deterministic, portable across wasm/native/JS, and suitable for
CI and Mooncakes consumers.

## Modules

- `metainfo.mbt`: typed torrent metadata, announce tiers, single-file and
  multi-file layouts, strict validation, and canonical `info` extraction.
- `torrent_files.mbt`: safe path normalization, file-tree flattening, total
  length, piece count, piece/file offset mapping, and piece-span queries.
- `magnet.mbt`: parse/build normalized Magnet URIs with v1 info hashes,
  display names, trackers, and duplicate-parameter handling.
- `torrent_builder.mbt`: deterministic builders for single-file and
  multi-file metadata, including canonical dictionary ordering.
- `torrent_report.mbt`: pure structured inspection summaries consumed by the
  CLI and documented examples.
- `cmd/main/main.mbt`: executable commands for inspect, validate, files,
  pieces, and magnet workflows using bytes supplied by the caller.

All public functions return typed values or existing package errors. No
filesystem or network access is required by the core package; callers can read
files and pass bytes explicitly. Paths are rejected when they are absolute,
empty, contain `..`, or contain platform separators that would escape the
torrent root.

## Compatibility and correctness

Existing decoder strictness remains unchanged: canonical integer syntax,
lexicographically ordered unique dictionary keys, bounded nesting, and no
trailing bytes. The typed metainfo layer adds required-field checks, piece
length validation, exact piece-count validation, and info-hash calculation
from the exact encoded `info` dictionary.

## Testing strategy

Tests are written before each new production behavior. Fixtures cover Linux
distribution torrents, single-file and multi-file torrents, private torrents,
magnet links, malformed metadata, path traversal, duplicate trackers, Unicode
names, piece boundaries, overflow-safe lengths, and canonical round trips.
The CI matrix runs format, interface generation, check, build, regular tests,
native tests, and package verification on Ubuntu, macOS, and Windows.

## Acceptance target

The extension targets more than 4,000 effective production MoonBit source
lines, with meaningful APIs and tests rather than filler. README examples,
CHANGELOG, contribution instructions, and the acceptance report will document
the public surface, reproducible commands, compatibility, and known limits.
