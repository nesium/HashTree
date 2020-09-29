import CryptoKit

extension Digest {
  var hashString: String? {
    self.compactMap { String(format: "%02x", $0) }.joined()
  }
}
