import CryptoKit
import Foundation

public enum HashTree<Hash: Hashable> {
  case empty
  indirect case node(
    hash: Hash,
    left: HashTree<Hash>,
    right: HashTree<Hash>
  )
}

extension HashTree {
  public init<Hasher: HashFunction, S: Sequence>(
    _: Hasher.Type,
    hashes: S
  ) where Hasher.Digest == Hash, S.Element == Hash {
    var nodes = hashes.map(Self.leaf)

    guard !nodes.isEmpty else {
      self = .empty
      return
    }

    var result = [Self]()

    while !nodes.isEmpty {
      let left = nodes.removeFirst()
      let right = nodes.isEmpty ? left : nodes.removeFirst()

      result.append(.parent(Hasher.self, left: left, right: right))

      if nodes.isEmpty, result.count > 1 {
        nodes = result
        result.removeAll()
      }
    }

    self = result.first!
  }

  public static func leaf(hash: Hash) -> HashTree<Hash> {
    .node(hash: hash, left: .empty, right: .empty)
  }

  public static func parent<Hasher: HashFunction>(
    _: Hasher.Type, left: Self, right: Self
  ) -> HashTree<Hasher.Digest> where Hasher.Digest == Hash {
    switch (left, right) {
    case let (.node(leftHash, _, _), .node(rightHash, _, _)):
      var hash = Hasher()
      leftHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
      }
      rightHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), left: left, right: right)

    case let (.node(leftHash, _, _), .empty):
      var hash = Hasher()
      leftHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), left: left, right: right)

    case let (.empty, .node(rightHash, _, _)):
      var hash = Hasher()
      rightHash.withUnsafeBytes { ptr in
        hash.update(bufferPointer: ptr)
        hash.update(bufferPointer: ptr)
      }
      return .node(hash: hash.finalize(), left: left, right: right)

    case (.empty, .empty):
      return .empty
    }
  }
}

extension HashTree {
  var hash: Hash? {
    switch self {
    case let .node(hash, _, _):
      return hash
    case .empty:
      return nil
    }
  }

  var isLeaf: Bool {
    switch self {
    case .node(_, .empty, .empty):
      return true
    case .node:
      return false
    case .empty:
      return true
    }
  }
}

extension HashTree: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.node(lHash, _, _), .node(rHash, _, _)):
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
  public func difference(from other: Self) -> Set<Hash> {
    switch (self, other) {
    case let (.node(lHash, ll, lr), .node(rHash, rl, rr)):
      if lHash == rHash {
        return []
      }

      switch self {
      case let .node(hash: hash, left: .empty, right: .empty):
        return [hash]
      case .node, .empty:
        break
      }

      var result = Set<Hash>()
      result.formUnion(ll.difference(from: rl))
      result.formUnion(lr.difference(from: rr))
      return result

    case (.empty, .node):
      return []
    case (.node, .empty):
      return []
    case (.empty, .empty):
      return []
    }
  }
}
