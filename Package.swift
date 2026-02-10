// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "CodesignAudit",
	platforms: [
		.macOS(.v26),
	],
	products: [
		.executable(name: "csa", targets: ["CodesignAuditCLI"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
		.package(url: "https://github.com/AvdLee/appstoreconnect-swift-sdk.git", from: "4.2.0"),
	],
	targets: [
		.executableTarget(
			name: "CodesignAuditCLI",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "AppStoreConnect-Swift-SDK", package: "appstoreconnect-swift-sdk"),
			],
			path: "src/CodesignAuditCLI/Sources"
		)
	]
)
