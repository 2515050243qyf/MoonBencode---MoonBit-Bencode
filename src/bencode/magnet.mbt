///|
/// A normalized, network-independent Magnet URI.
pub(all) struct MagnetLink {
  info_hash : Bytes
  display_name : Bytes?
  trackers : Array[Bytes]
  exact_sources : Array[Bytes]
  keywords : Array[Bytes]
} derive(Eq, Debug)

///|
pub fn MagnetLink::new(info_hash : Bytes) -> MagnetLink raise TorrentError {
  if info_hash.length() != 20 {
    raise InvalidMetadata("a v1 info hash must contain 20 bytes")
  }
  {
    info_hash,
    display_name: None,
    trackers: [],
    exact_sources: [],
    keywords: [],
  }
}

///|
pub fn MagnetLink::with_name(self : MagnetLink, name : Bytes) -> MagnetLink {
  { ..self, display_name: Some(name) }
}

///|
pub fn MagnetLink::with_tracker(
  self : MagnetLink,
  tracker : Bytes,
) -> MagnetLink {
  let result = self
  for existing in result.trackers {
    if existing == tracker {
      return result
    }
  }
  result.trackers.push(tracker)
  result
}

///|
pub fn MagnetLink::with_source(self : MagnetLink, source : Bytes) -> MagnetLink {
  let result = self
  for existing in result.exact_sources {
    if existing == source {
      return result
    }
  }
  result.exact_sources.push(source)
  result
}

///|
pub fn MagnetLink::with_keyword(
  self : MagnetLink,
  keyword : Bytes,
) -> MagnetLink {
  let result = self
  for existing in result.keywords {
    if existing == keyword {
      return result
    }
  }
  result.keywords.push(keyword)
  result
}

///|
fn hex_digit(value : Int) -> Byte {
  if value < 10 {
    b'0' + value.to_byte()
  } else {
    b'a' + (value - 10).to_byte()
  }
}

///|
fn hex_value(value : Byte) -> Int? {
  if value >= b'0' && value <= b'9' {
    Some((value - b'0').to_int())
  } else if value >= b'a' && value <= b'f' {
    Some((value - b'a').to_int() + 10)
  } else if value >= b'A' && value <= b'F' {
    Some((value - b'A').to_int() + 10)
  } else {
    None
  }
}

///|
fn to_hex(value : Bytes) -> Bytes {
  let output : Array[Byte] = []
  for byte in value {
    output.push(hex_digit(byte.to_int() >> 4))
    output.push(hex_digit(byte.to_int() & 15))
  }
  Bytes::from_array(output)
}

///|
fn from_hex(value : Bytes) -> Bytes raise TorrentError {
  if value.length() != 40 {
    raise InvalidMetadata("btih must be 40 hexadecimal characters")
  }
  let output : Array[Byte] = []
  for i = 0; i < value.length(); i = i + 2 {
    match (hex_value(value[i]), hex_value(value[i + 1])) {
      (Some(high), Some(low)) => output.push(((high << 4) | low).to_byte())
      _ => raise InvalidMetadata("btih contains a non-hexadecimal character")
    }
  }
  Bytes::from_array(output)
}

///|
fn unreserved(value : Byte) -> Bool {
  (value >= b'a' && value <= b'z') ||
  (value >= b'A' && value <= b'Z') ||
  (value >= b'0' && value <= b'9') ||
  value == b'-' ||
  value == b'_' ||
  value == b'.' ||
  value == b'~'
}

///|
fn percent_encode(value : Bytes) -> Bytes {
  let output : Array[Byte] = []
  for byte in value {
    if unreserved(byte) {
      output.push(byte)
    } else {
      output.push(b'%')
      output.push(hex_digit(byte.to_int() >> 4))
      output.push(hex_digit(byte.to_int() & 15))
    }
  }
  Bytes::from_array(output)
}

///|
fn percent_decode(value : Bytes) -> Bytes raise TorrentError {
  let output : Array[Byte] = []
  let mut i = 0
  while i < value.length() {
    if value[i] == b'%' {
      if i + 2 >= value.length() {
        raise InvalidMetadata("truncated percent escape")
      }
      match (hex_value(value[i + 1]), hex_value(value[i + 2])) {
        (Some(high), Some(low)) => output.push(((high << 4) | low).to_byte())
        _ => raise InvalidMetadata("invalid percent escape")
      }
      i += 3
    } else {
      output.push(value[i])
      i += 1
    }
  }
  Bytes::from_array(output)
}

///|
fn starts_with(value : Bytes, prefix : Bytes) -> Bool {
  if prefix.length() > value.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn index_of(value : Bytes, needle : Byte, start : Int) -> Int? {
  for i = start; i < value.length(); i = i + 1 {
    if value[i] == needle {
      return Some(i)
    }
  }
  None
}

///|
fn add_query(
  result : Array[Byte],
  key : Bytes,
  value : Bytes,
  first : Bool,
) -> Bool {
  if !first {
    result.push(b'&')
  }
  for byte in key {
    result.push(byte)
  }
  result.push(b'=')
  for byte in value {
    result.push(byte)
  }
  false
}

///|
pub fn MagnetLink::to_uri(self : MagnetLink) -> Bytes {
  let result : Array[Byte] = []
  for byte in b"magnet:?xt=urn:btih:" {
    result.push(byte)
  }
  for byte in to_hex(self.info_hash) {
    result.push(byte)
  }
  let mut first = false
  match self.display_name {
    Some(name) => first = add_query(result, b"dn", percent_encode(name), first)
    None => ()
  }
  for tracker in self.trackers {
    first = add_query(result, b"tr", percent_encode(tracker), first)
  }
  for source in self.exact_sources {
    first = add_query(result, b"as", percent_encode(source), first)
  }
  for keyword in self.keywords {
    first = add_query(result, b"kt", percent_encode(keyword), first)
  }
  Bytes::from_array(result)
}

///|
pub fn MagnetLink::from_uri(uri : Bytes) -> MagnetLink raise TorrentError {
  if !starts_with(uri, b"magnet:?") {
    raise InvalidMetadata("URI must use the magnet scheme")
  }
  let mut hash : Bytes? = None
  let mut display_name : Bytes? = None
  let trackers : Array[Bytes] = []
  let exact_sources : Array[Bytes] = []
  let keywords : Array[Bytes] = []
  let mut cursor = 8
  while cursor < uri.length() {
    let amp = match index_of(uri, b'&', cursor) {
      Some(pos) => pos
      None => uri.length()
    }
    let eq = match index_of(uri, b'=', cursor) {
      Some(pos) => pos
      None => amp
    }
    if eq < amp {
      let key = uri.view(start=cursor, end=eq).to_owned()
      let encoded = uri.view(start=eq + 1, end=amp).to_owned()
      let value = percent_decode(encoded)
      if key == b"xt" && starts_with(value, b"urn:btih:") {
        hash = Some(
          from_hex(value.view(start=9, end=value.length()).to_owned()),
        )
      } else if key == b"dn" {
        display_name = Some(value)
      } else if key == b"tr" {
        let mut duplicate = false
        for existing in trackers {
          if existing == value {
            duplicate = true
          }
        }
        if !duplicate {
          trackers.push(value)
        }
      } else if key == b"as" {
        let mut duplicate = false
        for existing in exact_sources {
          if existing == value {
            duplicate = true
          }
        }
        if !duplicate {
          exact_sources.push(value)
        }
      } else if key == b"kt" {
        let mut duplicate = false
        for existing in keywords {
          if existing == value {
            duplicate = true
          }
        }
        if !duplicate {
          keywords.push(value)
        }
      }
    }
    cursor = if amp == uri.length() { uri.length() } else { amp + 1 }
  }
  match hash {
    Some(value) =>
      { info_hash: value, display_name, trackers, exact_sources, keywords }
    None => raise InvalidMetadata("magnet URI is missing a v1 btih")
  }
}

///|
pub fn MagnetLink::has_tracker(self : MagnetLink, value : Bytes) -> Bool {
  for tracker in self.trackers {
    if tracker == value {
      return true
    }
  }
  false
}

///|
pub fn MagnetLink::tracker_count(self : MagnetLink) -> Int {
  self.trackers.length()
}

///|
pub fn MagnetLink::source_count(self : MagnetLink) -> Int {
  self.exact_sources.length()
}

///|
pub fn MagnetLink::keyword_count(self : MagnetLink) -> Int {
  self.keywords.length()
}

///|
pub fn MagnetLink::has_name(self : MagnetLink) -> Bool {
  self.display_name is Some(_)
}

///|
pub fn MagnetLink::is_private(self : MagnetLink) -> Bool {
  self.trackers.length() > 0 && self.exact_sources.length() == 0
}

///|
pub fn MagnetLink::without_trackers(self : MagnetLink) -> MagnetLink {
  { ..self, trackers: [] }
}

///|
pub fn MagnetLink::without_name(self : MagnetLink) -> MagnetLink {
  { ..self, display_name: None }
}

///|
pub fn MagnetLink::without_sources(self : MagnetLink) -> MagnetLink {
  { ..self, exact_sources: [] }
}

///|
pub fn MagnetLink::without_keywords(self : MagnetLink) -> MagnetLink {
  { ..self, keywords: [] }
}

///|
pub fn MagnetLink::normalized(self : MagnetLink) -> MagnetLink {
  self.without_trackers().with_tracker_array(self.trackers)
}

///|
fn MagnetLink::with_tracker_array(
  self : MagnetLink,
  values : Array[Bytes],
) -> MagnetLink {
  let result = { ..self, trackers: [] }
  for value in values {
    let _ = result.with_tracker(value)
  }
  result
}
