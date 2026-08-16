# MoonBencode Torrent Toolkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, cross-platform BitTorrent metainfo toolkit on top of the existing MoonBencode codec.

**Architecture:** Keep the existing codec stable and add pure typed modules for metainfo validation, safe file layout analysis, magnet URI handling, deterministic torrent construction, and structured reports. The CLI calls these pure APIs and never owns parsing rules.

**Tech Stack:** Current MoonBit 0.10.x-compatible syntax, `moon.mod`, `moon.pkg`, native/wasm-compatible standard library, GitHub Actions and Mooncakes.

---

### Task 1: Metainfo domain model

**Files:**
- Create: `src/bencode/metainfo.mbt`
- Test: `src/bencode/metainfo_test.mbt`

- [x] Write failing tests for single-file metadata, multi-file metadata, required fields, private flag, and invalid piece lengths.
- [x] Run focused and full regular/native suites.
- [x] Implement typed metadata extraction, validation, announce tiers, and exact info dictionary encoding.
- [x] Commit the typed torrent metainfo implementation.

### Task 2: File layout and piece planning

**Files:**
- Create: `src/bencode/torrent_files.mbt`
- Test: `src/bencode/torrent_files_test.mbt`

- [x] Write tests for safe path validation, flattening, total size, piece counts, offsets, and cross-file piece spans.
- [x] Implement immutable file entries, normalized paths, overflow-safe totals, and deterministic piece planning.
- [x] Verify ordinary, boundary, and native tests.
- [x] Commit the torrent file layout implementation.

### Task 3: Magnet URI support

**Files:**
- Create: `src/bencode/magnet.mbt`
- Test: `src/bencode/magnet_test.mbt`

- [x] Write tests for v1 hash parsing, percent encoding, display names, trackers, duplicates, and invalid parameters.
- [x] Implement normalized parse/build functions without network or filesystem dependencies.
- [x] Verify all tests on the native target.
- [x] Commit the normalized magnet URI implementation.

### Task 4: Deterministic builders and reports

**Files:**
- Create: `src/bencode/torrent_builder.mbt`
- Create: `src/bencode/torrent_report.mbt`
- Test: `src/bencode/torrent_builder_test.mbt`
- Test: `src/bencode/torrent_report_test.mbt`

- [x] Write tests for single-file and multi-file builders, canonical round trips, report summaries, and real distribution fixtures.
- [x] Implement builders and report values by composing the typed metainfo and file-layout modules.
- [x] Verify canonical bytes, exact info_hash values, and native tests.
- [x] Commit deterministic torrent builders and reports.

### Task 5: CLI workflows and documentation

**Files:**
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/moon.pkg`
- Modify: `README.md`, `README.zh.md`, `README.mbt.md`
- Modify: `CHANGELOG.md`, `MoonBencode_Report.md`

- [x] Add executable commands for inspect, validate, files, pieces, magnet, and profile.
- [x] Add real scenario fixtures and command examples to the README.
- [x] Run each deterministic command.
- [x] Commit the torrent toolkit CLI workflows.

### Task 6: Cross-platform toolchain and acceptance audit

**Files:**
- Modify: `.github/workflows/moonbit.yml`
- Create: `.github/workflows/release-check.yml`
- Modify: `CONTRIBUTING.md`, `CHANGELOG.md`

- [x] Configure latest Moon CLI setup and Linux/macOS/Windows checks for version, format diff, info diff, check, build, regular/native tests, and CLI smoke tests.
- [x] Run every locally supported command and inspect generated interfaces.
- [x] Recount effective production lines, inspect license/remotes/default branches/history, and verify both repositories have matching source trees.
- [x] Commit the cross-platform acceptance checks.
