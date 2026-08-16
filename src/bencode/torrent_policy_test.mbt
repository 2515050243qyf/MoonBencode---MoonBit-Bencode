///|
test "strict_policy_reports_tracker_and_empty_file_risks" {
  let value = decode(
    b"d4:infod6:lengthi16384e4:name8:demo.iso12:piece lengthi16384e6:pieces20:12345678901234567890ee",
  )
  let meta = TorrentMeta::from_bvalue(value)
  let assessment = TorrentPolicy::strict().requiring_tracker().assess(meta)
  assert_eq(assessment.is_accepted(), false)
  assert_eq(assessment.violation_count(), 1)
  assert_eq(assessment.risk_level(), b"reject")
}
