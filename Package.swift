// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "HashTree",
  platforms: [
    .iOS("13.0"),
    .macOS("10.15"),
  ],
  products: [
    .library(
      name: "HashTree",
      targets: ["HashTree"]
    ),

  ],
  targets: [
    .target(name: "HashTree"),
    .testTarget(
      name: "HashTreeTests",
      dependencies: ["HashTree"]
    ),
  ]
)
