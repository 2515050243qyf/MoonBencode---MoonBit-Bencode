# MoonBencode (基于 MoonBit 的 Bencode 库)

MoonBencode 是一个高性能且成熟的 Bencode 序列化与反序列化库，完全使用 MoonBit 编写。Bencode 是 BitTorrent 点对点文件共享协议所使用的数据编码格式。

## 特性

- **健壮的解码器**: 安全解析 `i...e`, `<len>:<string>`, `l...e` 和 `d...e` 并转换为 MoonBit AST 抽象语法树。
- **高保真编码器**: 能够将 MoonBit AST 编码回严格的 Bencode `Bytes`，保证字节级别的保真度。
- **高性能**: 采用高度优化的数组与字节序列操作，且零外部依赖。
- **JSON 互操作性**: 支持将 Bencode AST 无损/有损地转换为 JSON，以及从 JSON 重新构造成符合键字母序排序的 canonical Bencode AST。
- **路径快速查询**: 支持通过指定嵌套键路径快速定位并获取元素。
- **种子哈希支持**: 库内置了纯 MoonBit 实现的 SHA-1 算法，支持一键计算 BitTorrent 种子文件（info_hash）的安全指纹。
- **强类型种子元数据**：支持单文件/多文件种子、piece 数量、tracker 层级、私有种子和安全相对路径校验。
- **文件与 Piece 规划**：支持文件偏移、piece 跨文件映射、目录统计和确定性下载计划。
- **Magnet URI**：支持 v1 info_hash、显示名称、tracker、来源和关键词的解析与规范化生成。
- **安全策略**：支持资源限制、重复路径、可疑名称和生产可用性评估。

## 安装与依赖配置

### 1. 添加依赖到项目中

在你的项目根目录下，运行命令行工具添加依赖：

```bash
moon add 2515050243qyf/moon_bencode
```

或者直接编辑你项目的 `moon.mod` 文件，在 `import` 部分添加：

```json
import {
  "2515050243qyf/moon_bencode" = "0.2.0"
}
```

### 2. 导入包到模块中

在你想使用该库的包对应的 `moon.pkg`（例如 `moon.pkg.json` 或 `moon.pkg`）中，添加依赖声明：

```json
{
  "deps": {
    "2515050243qyf/moon_bencode/src/bencode": ""
  }
}
```

## 快速使用

配置完成后，在 `.mbt` 源码文件中，即可通过包别名前缀 `@bencode` 快速调用本库的方法：

```moonbit
pub fn main raise {
  // 解码 Bencode 字节串
  let val = @bencode.decode(b"d3:bar4:spam3:fooi42ee")
  println("Decoded: \{val}") 
  // 输出: BDict([(b"bar", BStr(b"spam")), (b"foo", BInt(42))])
  
  // 编码回 Bencode 字节串
  let bytes = @bencode.encode(val)
  println("Encoded: \{bytes}") 
  // 输出: b"d3:bar4:spam3:fooi42ee"
}
```

## 高级功能

### 1. JSON 互操作性
支持与 MoonBit 标准库的 `Json` 类型进行互转。其中 `from_json` 会自动对字典的键进行排序以满足规范：
```moonbit
pub fn example_json(val : @bencode.BValue) raise {
  // 转换为 Json 对象
  let json_obj = val.to_json()
  println(json_obj.stringify())

  // 从 Json 对象解析回 BValue
  let b_val = @bencode.BValue::from_json(json_obj)
}
```

### 2. 路径检索
无需深层嵌套匹配，使用路径数组即可快速查找子元素：
```moonbit
pub fn example_path(torrent : @bencode.BValue) {
  // 查找种子中 info 下的 name 字段
  match torrent.get_path(["info", "name"]) {
    Some(BStr(name)) => println("Name: \{name}")
    _ => println("Not found")
  }
}
```

### 3. 种子 Info Hash 计算
对于 BitTorrent 开发，计算 `info` 字典的 SHA-1 散列是核心。本库已完美集成纯 MoonBit 的 SHA-1 及 hash 计算器：
```moonbit
pub fn example_hash(torrent : @bencode.BValue) {
  match torrent.info_hash() {
    Some(hash_bytes) => println("Info Hash: \{hash_bytes}")
    None => println("Invalid torrent")
  }
}
```

## 数据类型

本库使用 MoonBit Enum 表示标准 Bencode 类型：
- `BInt(Int64)`: 整数类型。
- `BStr(Bytes)`: 字节串（未强制使用 UTF-8）。
- `BList(Array[BValue])`: 列表类型。
- `BDict(Array[(Bytes, BValue)])`: 字典类型（键已按字典序排好）。

## 命令行常用操作

本库提供以下标准命令供开发者使用：

- **运行语法检查**: `moon check --deny-warn`
- **执行构建**: `moon build`
- **运行测试用例**: `moon test --deny-warn`
- **检查格式规范**: `moon fmt --check`

命令行工具还提供可复现的真实场景演示：

```bash
moon run cmd/main -- inspect
moon run cmd/main -- validate
moon run cmd/main -- files
moon run cmd/main -- pieces
moon run cmd/main -- magnet
moon run cmd/main -- profile
```

## 可复现验收

仓库 CI 使用最新 Moon CLI（当前编译器 `moonc 0.10.7`），并在 Linux、macOS、Windows 上执行。可在项目根目录运行同样的检查：

```bash
moon check --deny-warn
moon fmt --check
moon info
moon build
moon test --deny-warn
moon test --deny-warn --target native
```

`moon info` 会生成公开接口文件 `pkg.generated.mbti`。0.10.x CLI 的
`moon info` 不支持 `--deny-warn`，因此警告检查由 `moon check --deny-warn`
和 `moon test --deny-warn` 负责。

测试覆盖严格整数与字符串校验、字典规范序与重复键、畸形输入、嵌套深度限制、
零拷贝视图、JSON 转换、路径查询、SHA-1 `info_hash`、Linux ISO 元数据、
嵌套 MoonBit 源码树、私有种子、Magnet 往返、piece 规划、安全策略、目录
查询和 Bencode 结构分析。当前生产 `.mbt` 代码已超过 4,000 行。
如需查看覆盖率，可运行：

```bash
moon test --deny-warn --enable-coverage
moon coverage report -f summary
```

## 开源协议

Apache-2.0
