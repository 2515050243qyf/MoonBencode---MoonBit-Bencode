///|
test "linux_distribution_fixture_is_valid_and_queryable" {
  let value = fixture_linux_iso()
  let meta = TorrentMeta::from_bvalue(value)
  let query = TorrentQuery::new(meta)
  assert_eq(query.file_count(), 1)
  assert_eq(query.piece_count(), 128)
  assert_eq(validation_matches_piece_count(meta), true)
  assert_eq(validation_is_reproducible(meta), true)
}

///|
test "source_tree_fixture_reports_nested_realistic_layout" {
  let value = fixture_source_tree()
  let meta = TorrentMeta::from_bvalue(value)
  let metrics = TorrentMetrics::from_meta(meta)
  let security = security_report(
    TorrentLayout::new(meta.files, meta.piece_length),
    1048576L,
  )
  assert_eq(meta.files.length(), 4)
  assert_eq(metrics.max_depth, 3)
  assert_eq(security.is_safe(), true)
  assert_eq(metrics.has_extension(b"mbt"), true)
}

///|
test "piece_plan_and_magnet_are_usable_for_application_workflow" {
  let value = fixture_linux_iso()
  let meta = TorrentMeta::from_bvalue(value)
  let plan = DownloadPlan::from_layout(
    TorrentLayout::new(meta.files, meta.piece_length),
  )
  let magnet = MagnetLink::new(meta.info_hash).with_name(meta.name)
  assert_eq(plan.piece_count(), 128)
  assert_eq(plan.valid_progress(64), true)
  assert_eq(magnet.has_name(), true)
  assert_eq(MagnetLink::from_uri(magnet.to_uri()).info_hash, meta.info_hash)
}

///|
test "bvalue_profile_and_canonical_transform_are_stable" {
  let value = fixture_private_tree()
  let walker = BValueWalker::new(value)
  let statistics = profile(value)
  assert_eq(walker.is_metadata(), true)
  assert_eq(statistics.has_dictionaries(), true)
  assert_eq(metainfo_is_canonical(value), true)
  assert_eq(metainfo_is_round_trippable(value), true)
}
