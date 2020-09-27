import CryptoKit
@testable import HashTree
import XCTest

final class HashTreeTests: XCTestCase {
  func testExample() {
    let left = HashTree.leaf(
      hash: SHA256.hash(data: Data("hello".utf8)),
      value: "hello"
    )
    let right = HashTree.leaf(
      hash: SHA256.hash(data: Data("world".utf8)),
      value: "world"
    )
    let tree = HashTree.parent(SHA256.self, value: "helloworld", left: left, right: right)

    XCTAssertEqual(
      tree.hashString,
      "7305db9b2abccd706c256db3d97e5ff48d677cfe4d3a5904afb7da0e3950e1e2"
    )
  }

  static var allTests = [
    ("testExample", testExample),
  ]
}
