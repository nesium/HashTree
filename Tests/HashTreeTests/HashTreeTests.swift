import CryptoKit
@testable import HashTree
import XCTest

final class HashTreeTests: XCTestCase {
  func testParent() {
    let tree = HashTree.parent(
      SHA256.self,
      value: "helloworld",
      left: makeLeaf("hello"),
      right: makeLeaf("world")
    )

    XCTAssertEqual(
      tree.hashString,
      "7305db9b2abccd706c256db3d97e5ff48d677cfe4d3a5904afb7da0e3950e1e2"
    )
  }

  func testInitWithEmptyLeafNodesArray() {
    let tree = HashTree<SHA256Digest, String>(SHA256.self, leafNodes: [], joinValues: +)
    XCTAssertEqual(tree, .empty)
  }

  func testInitWithOnlyEmptyLeafNodes() {
    let tree = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [.empty, .empty],
      joinValues: +
    )
    XCTAssertEqual(tree, .empty)
  }

  func testInitWithSomeEmptyLeafNodes() {
    let tree = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [makeLeaf("a"), .empty, makeLeaf("b")],
      joinValues: +
    )
    XCTAssertEqual(
      tree,
      .parent(SHA256.self, value: "ab", left: makeLeaf("a"), right: makeLeaf("b"))
    )
  }

  func testInitWithOddNumberOfLeafs() {
    let tree = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [makeLeaf("a"), makeLeaf("b"), makeLeaf("c")],
      joinValues: +
    )
    XCTAssertEqual(
      tree,
      .parent(
        SHA256.self,
        value: "abcc",
        left: .parent(SHA256.self, value: "ab", left: makeLeaf("a"), right: makeLeaf("b")),
        right: .parent(SHA256.self, value: "cc", left: makeLeaf("c"), right: makeLeaf("c"))
      )
    )
  }

  func testInitWithEvenNumberOfLeafs() {
    let tree = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [makeLeaf("a"), makeLeaf("b"), makeLeaf("c"), makeLeaf("d")],
      joinValues: +
    )
    XCTAssertEqual(
      tree,
      .parent(
        SHA256.self,
        value: "abcd",
        left: .parent(SHA256.self, value: "ab", left: makeLeaf("a"), right: makeLeaf("b")),
        right: .parent(SHA256.self, value: "cd", left: makeLeaf("c"), right: makeLeaf("d"))
      )
    )
  }

  func testDiff() {
    let treeA = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [
        makeLeaf("1"),
        makeLeaf("2"),
        makeLeaf("3"),
        makeLeaf("4"),
        makeLeaf("5"),
        makeLeaf("6"),
        makeLeaf("7"),
        makeLeaf("8"),
      ],
      joinValues: +
    )

    let treeB = HashTree<SHA256Digest, String>(
      SHA256.self,
      leafNodes: [
        makeLeaf("11"),
        makeLeaf("2"),
        makeLeaf("3"),
        makeLeaf("44"),
        makeLeaf("5"),
        makeLeaf("6"),
        makeLeaf("77"),
        makeLeaf("88"),
      ],
      joinValues: +
    )

    let diff = treeA.difference(from: treeB)
    XCTAssertEqual(diff, [makeLeaf("1"), makeLeaf("4"), makeLeaf("7"), makeLeaf("8")])
  }
}

extension HashTreeTests {
  private func makeLeaf(_ value: String) -> HashTree<SHA256Digest, String> {
    HashTree.leaf(hash: SHA256.hash(data: Data(value.utf8)), value: value)
  }
}
