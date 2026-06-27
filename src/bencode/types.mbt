pub enum BValue {
  BInt(Int64)
  BStr(Bytes)
  BList(Array[BValue])
  BDict(Array[(String, BValue)])
} derive(Eq, Debug)

pub suberror DecodeError {
  InvalidFormat(String)
  UnexpectedEOF
} derive(Eq, Debug)
