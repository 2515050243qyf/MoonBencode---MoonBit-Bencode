# MoonBencode (基于 MoonBit 的 Bencode 库)

MoonBencode 是一个高性能且成熟的 Bencode 序列化与反序列化库，完全使用 MoonBit 编写。Bencode 是 BitTorrent 点对点文件共享协议所使用的数据编码格式。

## 特性

- **健壮的解码器**: 安全解析 `i...e`, `<len>:<string>`, `l...e` 和 `d...e` 并转换为 MoonBit AST 抽象语法树。
- **高保真编码器**: 能够将 MoonBit AST 编码回严格的 Bencode `Bytes`，保证字节级别的保真度。
- **高性能**: 采用高度优化的数组与字节切片操作，且零外部依赖。
- **成熟生态**: 支持标准 Bencode 所有特性，是 MoonBit 生态中 BitTorrent 协议支持的基石组件。

## 安装

在你的 `moon.pkg.json` 依赖中添加：

```json
{
  "deps": {
    "qyf795201/moon_bencode": "1.0.0"
  }
}
```

## 快速使用

```moonbit
import "qyf795201/moon_bencode/src/bencode"

pub fn main {
  // 解码 Bencode 字符串
  let val = bencode::decode(b"d3:bar4:spam3:fooi42ee")!
  println(val) 
  // 输出: BDict([(b"bar", BStr(b"spam")), (b"foo", BInt(42))])
  
  // 将 AST 重新编码为 Bytes 字节流
  let bytes = bencode::encode(val)
  println(bytes) 
  // 输出: b"d3:bar4:spam3:fooi42ee"
}
```

## 数据类型

本库使用 MoonBit Enum 表示标准 Bencode 类型：
- `BInt(Int64)`: 整数类型。
- `BStr(Bytes)`: 字节串（因 Bencode 的特性，字符串均由字节流表示，未强制使用 UTF-8）。
- `BList(Array[BValue])`: 列表类型。
- `BDict(Array[(Bytes, BValue)])`: 字典类型。

## 开源协议

Apache-2.0
