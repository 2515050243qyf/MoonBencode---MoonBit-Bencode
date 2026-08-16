///|
fn main raise {
  let args = @env.args()
  let command = if args.length() > 1 {
    @bencode.parse_command(@utf8.encode(args[1]))
  } else {
    @bencode.Help
  }
  let value = @bencode.fixture_linux_iso()
  match command {
    @bencode.Help => {
      println("MoonBencode torrent toolkit")
      println("commands: inspect validate files pieces magnet profile")
    }
    @bencode.Inspect => {
      let meta = @bencode.TorrentMeta::from_bvalue(value)
      println("inspect: validated Linux distribution fixture")
      println(
        "files=\{meta.files.length()} pieces=\{meta.piece_count()} bytes=\{meta.total_length}",
      )
    }
    @bencode.Validate => {
      let meta = @bencode.TorrentMeta::from_bvalue(value)
      let report = @bencode.TorrentPolicy::strict().assess(meta)
      println("validate: \{report.risk_level()}")
    }
    @bencode.Files => {
      let meta = @bencode.TorrentMeta::from_bvalue(value)
      println("files: \{meta.files.length()} file(s)")
    }
    @bencode.Pieces => {
      let meta = @bencode.TorrentMeta::from_bvalue(value)
      println("pieces: \{meta.piece_count()} x \{meta.piece_length} bytes")
    }
    @bencode.Magnet => {
      let meta = @bencode.TorrentMeta::from_bvalue(value)
      let magnet = @bencode.MagnetLink::new(meta.info_hash).with_name(meta.name)
      println("magnet generated (\{magnet.to_uri().length()} bytes)")
    }
    @bencode.Profile => {
      let statistics = @bencode.profile(value)
      println(
        "profile: values=\{statistics.value_count()} depth=\{statistics.max_depth}",
      )
    }
  }
}
