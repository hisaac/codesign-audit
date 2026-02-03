import ArgumentParser
import Foundation
import AppStoreConnect_Swift_SDK
import CodesignAuditCore
import Noora

@main
struct CodesignAuditCLI: AsyncParsableCommand {
	@OptionGroup var options: GlobalOptions

	static let configuration = CommandConfiguration(
		commandName: "csa",
		abstract: "A tool for auditing code signatures.",
		discussion: "This tool helps in auditing code signatures for security and compliance.",
		version: "1.0.0",
		subcommands: [],
		defaultSubcommand: nil
	)

	mutating func run() async throws {
		let loadedConfig = try await CodesignAuditConfigLoader.load(from: options.config)
		print(loadedConfig.rawContents)
	}
}

struct GlobalOptions: ParsableArguments {
	@Option(
		name: .long,
		help: "Path to the configuration file."
	)
	var config: String

	@Flag(
		name: .shortAndLong,
		help: "Enable verbose output."
	)
	var verbose = false
}
