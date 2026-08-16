///|
/// Pure command planning helpers shared by platform-specific CLI frontends.
pub(all) enum TorrentCommand {
  Inspect
  Validate
  Files
  Pieces
  Magnet
  Profile
  Help
} derive(Eq, Debug)

///|
pub fn parse_command(value : Bytes) -> TorrentCommand {
  if value == b"inspect" {
    Inspect
  } else if value == b"validate" {
    Validate
  } else if value == b"files" {
    Files
  } else if value == b"pieces" {
    Pieces
  } else if value == b"magnet" {
    Magnet
  } else if value == b"profile" {
    Profile
  } else {
    Help
  }
}

///|
pub fn command_name(command : TorrentCommand) -> Bytes {
  match command {
    Inspect => b"inspect"
    Validate => b"validate"
    Files => b"files"
    Pieces => b"pieces"
    Magnet => b"magnet"
    Profile => b"profile"
    Help => b"help"
  }
}

///|
pub fn command_requires_metainfo(command : TorrentCommand) -> Bool {
  command != Help
}

///|
pub fn command_is_read_only(command : TorrentCommand) -> Bool {
  command == Inspect ||
  command == Validate ||
  command == Files ||
  command == Pieces ||
  command == Profile
}

///|
pub fn command_help() -> Array[Bytes] {
  [
    b"inspect  summarize validated torrent metadata", b"validate enforce strict metainfo and security policies",
    b"files    list normalized file paths and sizes", b"pieces   inspect piece count and file spans",
    b"magnet   build or parse a v1 magnet URI", b"profile  report Bencode tree statistics",
  ]
}

///|
pub fn command_exit_code(command : TorrentCommand, accepted : Bool) -> Int {
  if command == Help {
    0
  } else if accepted {
    0
  } else {
    1
  }
}

///|
pub fn command_output_kind(command : TorrentCommand) -> Bytes {
  if command == Magnet {
    b"uri"
  } else if command == Files {
    b"table"
  } else {
    b"summary"
  }
}

///|
pub fn command_can_run_without_network(command : TorrentCommand) -> Bool {
  command != Help || true
}

///|
pub fn command_version() -> Bytes {
  b"moon_bencode-cli/0.1.3"
}

///|
pub fn command_supported(command : TorrentCommand) -> Bool {
  command != Help || command_help().length() > 0
}

///|
pub fn command_all() -> Array[TorrentCommand] {
  [Inspect, Validate, Files, Pieces, Magnet, Profile, Help]
}

///|
pub fn command_count() -> Int {
  command_all().length()
}

///|
pub fn command_is_analysis(command : TorrentCommand) -> Bool {
  command == Inspect ||
  command == Profile ||
  command == Files ||
  command == Pieces
}

///|
pub fn command_is_validation(command : TorrentCommand) -> Bool {
  command == Validate
}
