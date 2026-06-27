pub(all) enum BValue {
  BInt(Int64)
  BStr(Bytes)
  BList(Array[BValue])
  BDict(Array[(Bytes, BValue)])
} derive(Eq, Debug)

pub impl Show for BValue with output(_self, logger) {
  logger.write_string("BValue")
}

pub suberror DecodeError {
  InvalidFormat(String)
  UnexpectedEOF
} derive(Eq, Debug)
