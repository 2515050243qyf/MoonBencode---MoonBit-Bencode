///|
/// Security-oriented checks for untrusted torrent metadata.
pub(all) struct TorrentSecurityReport {
  safe : Bool
  path_issues : Int
  duplicate_paths : Int
  oversized_files : Int
  suspicious_names : Int
  total_length : Int64
} derive(Eq, Debug)

///|
fn suspicious_component(value : Bytes) -> Bool {
  if value.length() == 0 || value == b"." || value == b".." {
    return true
  }
  if value[0] == b'~' || value[0] == b'$' {
    return true
  }
  for byte in value {
    if byte < 32 || byte == b':' || byte == b'|' {
      return true
    }
  }
  false
}

///|
pub fn security_report(
  layout : TorrentLayout,
  max_file_size : Int64,
) -> TorrentSecurityReport {
  let mut path_issues = 0
  let mut suspicious = 0
  let mut oversized = 0
  for file in layout.files() {
    if file.path.length() == 0 {
      path_issues += 1
    }
    for component in file.path {
      if suspicious_component(component) {
        suspicious += 1
      }
    }
    if file.length > max_file_size {
      oversized += 1
    }
  }
  let mut duplicate = 0
  for i = 0; i < layout.file_count(); i = i + 1 {
    for j = i + 1; j < layout.file_count(); j = j + 1 {
      if layout.files()[i].path == layout.files()[j].path {
        duplicate += 1
      }
    }
  }
  {
    safe: path_issues == 0 && duplicate == 0 && suspicious == 0,
    path_issues,
    duplicate_paths: duplicate,
    oversized_files: oversized,
    suspicious_names: suspicious,
    total_length: layout.total_length,
  }
}

///|
pub fn TorrentSecurityReport::is_safe(self : TorrentSecurityReport) -> Bool {
  self.safe
}

///|
pub fn TorrentSecurityReport::issue_count(self : TorrentSecurityReport) -> Int {
  self.path_issues + self.duplicate_paths + self.suspicious_names
}

///|
pub fn TorrentSecurityReport::has_path_issue(
  self : TorrentSecurityReport,
) -> Bool {
  self.path_issues > 0
}

///|
pub fn TorrentSecurityReport::has_duplicates(
  self : TorrentSecurityReport,
) -> Bool {
  self.duplicate_paths > 0
}

///|
pub fn TorrentSecurityReport::has_suspicious_names(
  self : TorrentSecurityReport,
) -> Bool {
  self.suspicious_names > 0
}

///|
pub fn TorrentSecurityReport::has_oversized_files(
  self : TorrentSecurityReport,
) -> Bool {
  self.oversized_files > 0
}

///|
pub fn TorrentSecurityReport::risk(self : TorrentSecurityReport) -> Bytes {
  if self.issue_count() > 0 {
    b"high"
  } else if self.oversized_files > 0 {
    b"medium"
  } else {
    b"low"
  }
}

///|
pub fn TorrentSecurityReport::same_safety(
  self : TorrentSecurityReport,
  other : TorrentSecurityReport,
) -> Bool {
  self.safe == other.safe && self.issue_count() == other.issue_count()
}

///|
pub fn TorrentSecurityReport::size_ratio(
  self : TorrentSecurityReport,
  limit : Int64,
) -> Int {
  if limit <= 0L {
    0
  } else {
    (self.total_length * 100L / limit).to_int()
  }
}

///|
pub fn safe_path(path : Array[Bytes]) -> Bool {
  if path.length() == 0 {
    return false
  }
  for part in path {
    if suspicious_component(part) {
      return false
    }
    for byte in part {
      if byte == b'/' || byte == b'\\' {
        return false
      }
    }
  }
  true
}

///|
pub fn safe_file(file : TorrentFile) -> Bool {
  safe_path(file.path) && file.length >= 0L
}

///|
pub fn safe_layout(layout : TorrentLayout) -> Bool {
  for file in layout.files() {
    if !safe_file(file) {
      return false
    }
  }
  true
}

///|
pub fn path_is_relative(path : Array[Bytes]) -> Bool {
  safe_path(path) && path[0].length() > 0 && path[0][0] != b'/'
}

///|
pub fn has_control_bytes(path : Array[Bytes]) -> Bool {
  for part in path {
    for byte in part {
      if byte < 32 {
        return true
      }
    }
  }
  false
}

///|
pub fn count_suspicious_files(layout : TorrentLayout) -> Int {
  let mut result = 0
  for file in layout.files() {
    if !safe_file(file) {
      result += 1
    }
  }
  result
}
