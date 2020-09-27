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
}

extension HashTree {
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
