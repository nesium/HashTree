import CryptoKit
import Foundation

public enum HashTree<Hash: Digest, Element> {
  case empty
  indirect case node(
    hash: Hash,
    value: Element,
    left: HashTree<Hash, Element>,
    right: HashTree<Hash, Element>
  )
}

extension HashTree {
  public init<Hasher: HashFunction, S: Sequence>(
    _: Hasher.Type,
    leafNodes: S,
    joinValues: (Element, Element) -> Element
  ) where Hasher.Digest == Hash, S.Element == Self {
    var nodesAndValues: [(node: Self, value: Element)] = leafNodes.compactMap { node in
      guard case let HashTree.node(_, value, _, _) = node else {
        return nil
      }
      return (node, value)
    }

    guard !nodesAndValues.isEmpty else {
      self = .empty
      return
    }

    var result = [(node: Self, value: Element)]()

    while !nodesAndValues.isEmpty {
      let left = nodesAndValues.removeFirst()
      let right = nodesAndValues.isEmpty ? left : nodesAndValues.removeFirst()
      let value = joinValues(left.value, right.value)

      result.append((.parent(Hasher.self, value: value, left: left.node, right: right.node), value))

      if nodesAndValues.isEmpty, result.count > 1 {
        nodesAndValues = result
        result.removeAll()
      }
    }

    self = result.first!.node
  }

  public static func leaf(hash: Hash, value: Element) -> HashTree<Hash, Element> {
    .node(hash: hash, value: value, left: .empty, right: .empty)
  }

  public static func parent<Hasher: HashFunction>(
    _: Hasher.Type, value: Element, left: Self, right: Self
  ) -> HashTree<Hasher.Digest, Element> where Hasher.Digest == Hash {
    switch (left, right) {
    case let (.node(leftHash, _, _, _), .node(rightHash, _, _, _)):
      var hash = Hasher()
      leftHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
      }
      rightHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), value: value, left: left, right: right)

    case let (.node(leftHash, _, _, _), .empty):
      var hash = Hasher()
      leftHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), value: value, left: left, right: right)

    case let (.empty, .node(rightHash, _, _, _)):
      var hash = Hasher()
      rightHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), value: value, left: left, right: right)

    case (.empty, .empty):
      return .empty
    }
  }
}

extension HashTree {
  var hash: Hash? {
    switch self {
    case let .node(hash, _, _, _):
      return hash
    case .empty:
      return nil
    }
  }

  var hashString: String? {
    self.hash?.compactMap { String(format: "%02x", $0) }.joined()
  }

  var isLeaf: Bool {
    switch self {
    case .node(_, _, .empty, .empty):
      return true
    case .node:
      return false
    case .empty:
      return true
    }
  }

  var value: Element? {
    switch self {
    case let .node(_, value, _, _):
      return value
    case .empty:
      return nil
    }
  }
}

extension HashTree: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.node(lHash, _, _, _), .node(rHash, _, _, _)):
      return lHash == rHash
    case (.empty, .empty):
      return true
    case (.node, _), (.empty, _):
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.hash)
  }
}

extension HashTree {
  public func difference(from other: Self) -> Set<Self> {
    switch (self, other) {
    case let (.node(lHash, _, ll, lr), .node(rHash, _, rl, rr)):
      if lHash == rHash {
        return []
      }

      if self.isLeaf {
        return [self]
      }

      var result = Set<Self>()
      result.formUnion(ll.difference(from: rl))
      result.formUnion(lr.difference(from: rr))
      return result

    case (.empty, .node):
      return [self]
    case (.node, .empty):
      return [self]
    case (.empty, .empty):
      return []
    }
  }
}
