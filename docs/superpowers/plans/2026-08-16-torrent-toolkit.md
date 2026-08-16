# MoonBencode Torrent Toolkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, cross-platform BitTorrent metainfo toolkit on top of the existing MoonBencode codec.

**Architecture:** Keep the existing codec stable and add pure typed modules for metainfo validation, safe file layout analysis, magnet URI handling, deterministic torrent construction, and structured reports. The CLI calls these pure APIs and never owns parsing rules.

**Tech Stack:** MoonBit 0.10.3-compatible syntax, `moon.mod`, `moon.pkg`, native/wasm-compatible standard library, GitHub Actions and Mooncakes.

---

### Task 1: Metainfo domain model

**Files:**
- Create: `src/bencode/metainfo.mbt`
- Test: `src/bencode/metainfo_test.mbt`

- [ ] Write failing tests for single-file metadata, multi-file metadata, required fields, private flag, and invalid piece lengths.
- [ ] Run `moon test --deny-warn --package 2515050243qyf/moon_bencode/src/bencode`; verify the new tests fail because the typed API is absent.
- [ ] Implement typed metadata extraction, validation, announce tiers, and exact info dictionary encoding.
- [ ] Run the focused tests and then the full regular/native suites.
- [ ] Commit `feat: add typed torrent metainfo validation`.

### Task 2: File layout and piece planning

**Files:**
- Create: `src/bencode/torrent_files.mbt`
- Test: `src/bencode/torrent_files_test.mbt`

- [ ] Write failing tests for safe path validation, flattening, total size, piece counts, offsets, and cross-file piece spans.
- [ ] Verify the tests fail for the missing layout API.
- [ ] Implement immutable file entries, normalized paths, overflow-safe totals, and deterministic piece planning.
- [ ] Verify ordinary, boundary, and native tests.
- [ ] Commit `feat: add torrent file layout analysis`.

### Task 3: Magnet URI support

**Files:**
- Create: `src/bencode/magnet.mbt`
- Test: `src/bencode/magnet_test.mbt`

- [ ] Write failing tests for v1 hash parsing, percent encoding, display names, trackers, duplicates, and invalid parameters.
- [ ] Verify the tests fail for the missing magnet API.
- [ ] Implement normalized parse/build functions without network or filesystem dependencies.
- [ ] Verify all tests on the native target.
- [ ] Commit `feat: add normalized magnet uri support`.

### Task 4: Deterministic builders and reports

**Files:**
- Create: `src/bencode/torrent_builder.mbt`
- Create: `src/bencode/torrent_report.mbt`
- Test: `src/bencode/torrent_builder_test.mbt`
- Test: `src/bencode/torrent_report_test.mbt`

- [ ] Write failing tests for single-file and multi-file builders, canonical round trips, report summaries, and real distribution fixtures.
- [ ] Verify the tests fail before implementation.
- [ ] Implement builders and report values by composing the typed metainfo and file-layout modules.
- [ ] Verify canonical bytes, exact info_hash values, and native tests.
- [ ] Commit `feat: add deterministic torrent builders and reports`.

### Task 5: CLI workflows and documentation

**Files:**
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/moon.pkg`
- Modify: `README.md`, `README.zh.md`, `README.mbt.md`
- Modify: `CHANGELOG.md`, `MoonBencode_Report.md`

- [ ] Add executable commands for inspect, validate, files, pieces, and magnet with documented byte-input examples.
- [ ] Add real scenario fixtures and command examples to the README.
- [ ] Run `moon run cmd/main --help` and each deterministic command.
- [ ] Commit `feat: expose torrent toolkit cli workflows`.

### Task 6: Cross-platform toolchain and acceptance audit

**Files:**
- Modify: `.github/workflows/moonbit.yml`
- Create: `.github/workflows/release-check.yml`
- Modify: `CONTRIBUTING.md`, `CHANGELOG.md`

- [ ] Pin setup-moonbit to 0.10.3 and add Linux/macOS/Windows checks for version, format diff, info diff, check, build, regular/native tests, and package dry-run.
- [ ] Run every locally supported command and inspect generated interfaces.
- [ ] Recount effective production lines, inspect license/remotes/default branches/history, and verify both repositories have identical source trees.
- [ ] Commit `ci: strengthen three-platform acceptance checks`.
