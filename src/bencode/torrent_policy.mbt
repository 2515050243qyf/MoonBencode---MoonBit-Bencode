///|
/// Application-facing limits for accepting untrusted torrent metadata.
pub(all) struct TorrentPolicy {
  max_files : Int
  max_total_length : Int64
  max_path_depth : Int
  max_piece_length : Int
  min_piece_length : Int
  require_tracker : Bool
  allow_private : Bool
  allow_empty_files : Bool
} derive(Eq, Debug)

///|
pub(all) struct TorrentAssessment {
  accepted : Bool
  violations : Array[String]
  warnings : Array[String]
  file_count : Int
  total_length : Int64
  piece_count : Int
} derive(Eq, Debug)

///|
pub fn TorrentPolicy::default() -> TorrentPolicy {
  {
    max_files: 100000,
    max_total_length: 9223372036854775807L,
    max_path_depth: 64,
    max_piece_length: 16777216,
    min_piece_length: 16384,
    require_tracker: false,
    allow_private: true,
    allow_empty_files: true,
  }
}

///|
pub fn TorrentPolicy::strict() -> TorrentPolicy {
  {
    max_files: 10000,
    max_total_length: 1099511627776L,
    max_path_depth: 32,
    max_piece_length: 4194304,
    min_piece_length: 16384,
    require_tracker: true,
    allow_private: true,
    allow_empty_files: false,
  }
}

///|
pub fn TorrentPolicy::with_max_files(
  self : TorrentPolicy,
  value : Int,
) -> TorrentPolicy {
  { ..self, max_files: value }
}

///|
pub fn TorrentPolicy::with_max_total_length(
  self : TorrentPolicy,
  value : Int64,
) -> TorrentPolicy {
  { ..self, max_total_length: value }
}

///|
pub fn TorrentPolicy::with_max_depth(
  self : TorrentPolicy,
  value : Int,
) -> TorrentPolicy {
  { ..self, max_path_depth: value }
}

///|
pub fn TorrentPolicy::with_piece_range(
  self : TorrentPolicy,
  minimum : Int,
  maximum : Int,
) -> TorrentPolicy {
  { ..self, min_piece_length: minimum, max_piece_length: maximum }
}

///|
pub fn TorrentPolicy::requiring_tracker(self : TorrentPolicy) -> TorrentPolicy {
  { ..self, require_tracker: true }
}

///|
pub fn TorrentPolicy::without_private(self : TorrentPolicy) -> TorrentPolicy {
  { ..self, allow_private: false }
}

///|
pub fn TorrentPolicy::without_empty_files(
  self : TorrentPolicy,
) -> TorrentPolicy {
  { ..self, allow_empty_files: false }
}

///|
fn check_policy(
  meta : TorrentMeta,
  policy : TorrentPolicy,
) -> TorrentAssessment raise TorrentError {
  let layout = TorrentLayout::new(meta.files, meta.piece_length)
  let violations : Array[String] = []
  let warnings : Array[String] = []
  if layout.file_count() > policy.max_files {
    violations.push("too many files")
  }
  if layout.total_length > policy.max_total_length {
    violations.push("total length exceeds policy")
  }
  if meta.piece_length < policy.min_piece_length {
    violations.push("piece length is too small")
  }
  if meta.piece_length > policy.max_piece_length {
    violations.push("piece length is too large")
  }
  if layout.max_depth() > policy.max_path_depth {
    violations.push("path depth exceeds policy")
  }
  if policy.require_tracker && meta.announce.length() == 0 {
    violations.push("tracker is required")
  }
  if !policy.allow_private && meta.is_private {
    violations.push("private torrents are not allowed")
  }
  if !policy.allow_empty_files && layout.empty_file_count() > 0 {
    violations.push("empty files are not allowed")
  }
  if layout.is_multi_file() && layout.directory_count() == 0 {
    warnings.push("multi-file torrent has no nested directory")
  }
  if meta.pieces.length() == 0 {
    warnings.push("torrent has no piece hashes")
  }
  {
    accepted: violations.length() == 0,
    violations,
    warnings,
    file_count: layout.file_count(),
    total_length: layout.total_length,
    piece_count: layout.piece_count(),
  }
}

///|
pub fn TorrentPolicy::assess(
  self : TorrentPolicy,
  meta : TorrentMeta,
) -> TorrentAssessment raise TorrentError {
  check_policy(meta, self)
}

///|
pub fn TorrentPolicy::accepts(
  self : TorrentPolicy,
  meta : TorrentMeta,
) -> Bool raise TorrentError {
  self.assess(meta).accepted
}

///|
pub fn TorrentAssessment::is_accepted(self : TorrentAssessment) -> Bool {
  self.accepted
}

///|
pub fn TorrentAssessment::violation_count(self : TorrentAssessment) -> Int {
  self.violations.length()
}

///|
pub fn TorrentAssessment::warning_count(self : TorrentAssessment) -> Int {
  self.warnings.length()
}

///|
pub fn TorrentAssessment::has_warnings(self : TorrentAssessment) -> Bool {
  self.warnings.length() > 0
}

///|
pub fn TorrentAssessment::is_large(
  self : TorrentAssessment,
  threshold : Int64,
) -> Bool {
  self.total_length >= threshold
}

///|
pub fn TorrentAssessment::is_many_files(
  self : TorrentAssessment,
  threshold : Int,
) -> Bool {
  self.file_count >= threshold
}

///|
pub fn TorrentAssessment::is_piece_heavy(
  self : TorrentAssessment,
  threshold : Int,
) -> Bool {
  self.piece_count >= threshold
}

///|
pub fn TorrentAssessment::first_violation(self : TorrentAssessment) -> String? {
  if self.violations.length() == 0 {
    None
  } else {
    Some(self.violations[0])
  }
}

///|
pub fn TorrentAssessment::first_warning(self : TorrentAssessment) -> String? {
  if self.warnings.length() == 0 {
    None
  } else {
    Some(self.warnings[0])
  }
}

///|
pub fn TorrentAssessment::score(self : TorrentAssessment) -> Int {
  if !self.accepted {
    0
  } else if self.warnings.length() == 0 {
    100
  } else {
    80
  }
}

///|
pub fn TorrentAssessment::risk_level(self : TorrentAssessment) -> Bytes {
  if !self.accepted {
    b"reject"
  } else if self.warnings.length() > 0 {
    b"review"
  } else {
    b"normal"
  }
}

///|
pub fn TorrentAssessment::same_scale(
  self : TorrentAssessment,
  other : TorrentAssessment,
) -> Bool {
  self.file_count == other.file_count && self.total_length == other.total_length
}
