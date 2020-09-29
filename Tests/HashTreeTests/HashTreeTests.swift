import CryptoKit
@testable import HashTree
import XCTest

extension String {
  var sha256Digest: SHA256Digest {
    SHA256.hash(data: Data(self.utf8))
  }
}

extension HashFunction {
  static func combining<S: Sequence>(_ hashes: S) -> Digest where S.Element == Digest {
    var hasher = Self()
    for hash in hashes {
      hash.withUnsafeBytes { ptr in
        hasher.update(bufferPointer: ptr)
      }
    }
    return hasher.finalize()
  }
}

final class HashTreeTests: XCTestCase {
  func testParent() {
    let tree = HashTree.parent(
      SHA256.self,
      left: .leaf(hash: "hello".sha256Digest),
      right: .leaf(hash: "world".sha256Digest)
    )

    XCTAssertEqual(
      tree.hash?.hashString,
      "7305db9b2abccd706c256db3d97e5ff48d677cfe4d3a5904afb7da0e3950e1e2"
    )
  }

  func testInitWithEmptyLeafNodesArray() {
    let tree = HashTree(SHA256.self, hashes: [])
    XCTAssertEqual(tree, .empty)
  }

  func testInitWithOddNumberOfLeafs() {
    let tree = HashTree(SHA256.self, hashes: ["a".sha256Digest, "b".sha256Digest, "c".sha256Digest])
    XCTAssertEqual(
      tree,
      .parent(
        SHA256.self,
        left: .node(
          hash: SHA256.combining(["a".sha256Digest, "b".sha256Digest]),
          left: .leaf(hash: "a".sha256Digest),
          right: .leaf(hash: "b".sha256Digest)
        ),
        right: .node(
          hash: SHA256.combining(["c".sha256Digest, "c".sha256Digest]),
          left: .leaf(hash: "c".sha256Digest),
          right: .leaf(hash: "c".sha256Digest)
        )
      )
    )
  }

  func testInitWithEvenNumberOfLeafs() {
    let tree = HashTree(
      SHA256.self,
      hashes: ["a".sha256Digest, "b".sha256Digest, "c".sha256Digest, "d".sha256Digest]
    )
    XCTAssertEqual(
      tree,
      .parent(
        SHA256.self,
        left: .node(
          hash: SHA256.combining(["a".sha256Digest, "b".sha256Digest]),
          left: .leaf(hash: "a".sha256Digest),
          right: .leaf(hash: "b".sha256Digest)
        ),
        right: .node(
          hash: SHA256.combining(["c".sha256Digest, "d".sha256Digest]),
          left: .leaf(hash: "c".sha256Digest),
          right: .leaf(hash: "d".sha256Digest)
        )
      )
    )
  }

  func testDifference() {
    let treeA = HashTree(
      SHA256.self,
      hashes: [
        "1".sha256Digest,
        "2".sha256Digest,
        "3".sha256Digest,
        "4".sha256Digest,
        "5".sha256Digest,
        "6".sha256Digest,
        "7".sha256Digest,
        "8".sha256Digest,
      ]
    )

    let treeB = HashTree(
      SHA256.self,
      hashes: [
        "11".sha256Digest,
        "2".sha256Digest,
        "3".sha256Digest,
        "44".sha256Digest,
        "5".sha256Digest,
        "6".sha256Digest,
        "77".sha256Digest,
        "88".sha256Digest,
      ]
    )

    let diff = treeA.difference(from: treeB)
    XCTAssertEqual(diff, ["1".sha256Digest, "4".sha256Digest, "7".sha256Digest, "8".sha256Digest])
  }
}
