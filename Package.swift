// swift-tools-version: 6.1

import PackageDescription

let package = Package(
	name: "CodesignAudit",
	platforms: [
		.macOS(.v15),
	],
	products: [
		.executable(name: "codesign-audit", targets: ["CodesignAuditCLI"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
		.package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.1"),
		.package(url: "https://github.com/AvdLee/appstoreconnect-swift-sdk.git", from: "4.2.0"),
		.package(url: "https://github.com/tuist/Noora.git", from: "0.54.0"),
	],
	targets: [
		.executableTarget(
			name: "CodesignAuditCLI",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Configuration", package: "swift-configuration"),
				.product(name: "AppStoreConnect-Swift-SDK", package: "appstoreconnect-swift-sdk"),
				.product(name: "Noora", package: "Noora"),
			],
			path: "src/CodesignAuditCLI/Sources"
		),
	]
)
