

// MARK: - JSON.Serializer

extension JSON {
  public struct Serializer {

    public struct Option: OptionSet {
      public init(rawValue: UInt8) { self.rawValue = rawValue }
      public let rawValue: UInt8

      /// Serialize `JSON.null` instead of skipping it
      public static let noSkipNull          = Option(rawValue: 0b0001)

      /// Serialize with formatting for user readability
      public static let prettyPrint         = Option(rawValue: 0b0010)
      
      /// will use windows style newlines for formatting. Boo. Implies `.prettyPrint`
      public static let windowsLineEndings  = Option(rawValue: 0b0110)
    }

    init(json: JSON, options: Option = []) {
      self.skipNull = !options.contains(.noSkipNull)
      self.prettyPrint = options.contains(.prettyPrint)
      self.useWindowsLineEndings = options.contains(.windowsLineEndings)
    }

    let skipNull: Bool
    let prettyPrint: Bool
    let useWindowsLineEndings: Bool
  }
}

extension JSON.Serializer {
  public static func serialize<O: TextOutputStream>(_ json: JSON, to stream: inout O, options: Option) throws {
    let writer = JSON.Serializer(json: json, options: options)
    try writer.writeValue(json, to: &stream)
  }

  public static func serialize(_ json: JSON, options: Option = []) throws -> String {
    var s = ""
    let writer = JSON.Serializer(json: json, options: options)
    try writer.writeValue(json, to: &s)
    return s
  }
}

extension JSON.Serializer {
  func writeValue<O: TextOutputStream>(_ value: JSON, to stream: inout O, indentLevel: Int = 0) throws {
    switch value {
    case .array(let a):
      try writeArray(a, to: &stream, indentLevel: indentLevel)

    case .bool(let b):
      writeBool(b, to: &stream)

    case .double(let d):
      try writeDouble(d, to: &stream)

    case .integer(let i):
      writeInteger(i, to: &stream)

    case .null where !skipNull:
      writeNull(to: &stream)

    case .string(let s):
      writeString(s, to: &stream)

    case .object(let o):
      try writeObject(o, to: &stream, indentLevel: indentLevel)

    default: break
    }
  }
}

extension JSON.Serializer {
  func writeNewlineIfNeeded<O: TextOutputStream>(to stream: inout O) {
    guard prettyPrint else { return }
    stream.write("\n")
  }

  func writeIndentIfNeeded<O: TextOutputStream>(_ indentLevel: Int, to stream: inout O) {
    guard prettyPrint else { return }

    // TODO: Look into a more effective way of adding to a string.

    for _ in 0..<indentLevel {
      stream.write("    ")
    }
  }
}

extension JSON.Serializer {

  func writeArray<O: TextOutputStream>(_ a: [JSON], to stream: inout O, indentLevel: Int = 0) throws {
    if a.isEmpty {
      stream.write("[]")
      return
    }

    stream.write("[")
    writeNewlineIfNeeded(to: &stream)
    var i = 0
    var nullsFound = 0
    for v in a {
      defer { i += 1 }
      if skipNull && v == .null {
        nullsFound += 1
        continue
      }
      if i != nullsFound { // check we have seen non null values
        stream.write(",")
        writeNewlineIfNeeded(to: &stream)
      }
      writeIndentIfNeeded(indentLevel + 1, to: &stream)
      try writeValue(v, to: &stream, indentLevel: indentLevel + 1)
    }
    writeNewlineIfNeeded(to: &stream)
    writeIndentIfNeeded(indentLevel, to: &stream)
    stream.write("]")
  }

  func writeObject<O: TextOutputStream>(_ o: [String: JSON], to stream: inout O, indentLevel: Int = 0) throws {
    if o.isEmpty {
      stream.write("{}")
      return
    }

    stream.write("{")
    writeNewlineIfNeeded(to: &stream)
    var i = 0
    var nullsFound = 0
    for (key, value) in o {
      defer { i += 1 }
      if skipNull && value == .null {
        nullsFound += 1
        continue
      }
      if i != nullsFound { // check we have seen non null values
        stream.write(",")
        writeNewlineIfNeeded(to: &stream)
      }
      writeIndentIfNeeded(indentLevel + 1, to: &stream)
      writeString(key, to: &stream)
      stream.write(prettyPrint ? ": " : ":")
      try writeValue(value, to: &stream, indentLevel: indentLevel + 1)
    }
    writeNewlineIfNeeded(to: &stream)
    writeIndentIfNeeded(indentLevel, to: &stream)
    stream.write("}")
  }

  func writeBool<O: TextOutputStream>(_ b: Bool, to stream: inout O) {
    switch b {
    case true:
      stream.write("true")

    case false:
      stream.write("false")
    }
  }

  func writeNull<O: TextOutputStream>(to stream: inout O) {
    stream.write("null")
  }

  func writeInteger<O: TextOutputStream>(_ i: Int64, to stream: inout O) {
    stream.write(i.description)
  }

  func writeDouble<O: TextOutputStream>(_ d: Double, to stream: inout O) throws {
    guard d.isFinite else { throw JSON.Serializer.Error.invalidNumber }
    stream.write(d.description)
  }

  func writeString<O: TextOutputStream>(_ s: String, to stream: inout O) {
    stream.write("\"")
    stream.write(s)
    stream.write("\"")
  }
}

extension JSON.Serializer {
  public enum Error: String, Swift.Error {
    case invalidNumber
  }
}