import ArgumentParser
import Foundation

@main
struct csa: AsyncParsableCommand {
	@OptionGroup var options: GlobalOptions
	@OptionGroup var apiOptions: AppStoreConnectOptions

	@Argument(help: "One or more App Store Connect team IDs.")
	var teamIDs: [String]

	static let configuration = CommandConfiguration(
		commandName: "csa",
		abstract: "A tool for auditing code signatures.",
		discussion: "This tool helps in auditing code signatures for security and compliance.",
		version: "1.0.0",
		subcommands: [],
		defaultSubcommand: nil
	)

	mutating func run() async throws {
		let app = CodesignAuditApp(
			options: options,
			apiOptions: apiOptions,
			teamIDs: teamIDs
		)
		try await app.run()
	}

	mutating func validate() throws {
		if teamIDs.isEmpty {
			throw ValidationError("Provide at least one team ID.")
		}
		if let days = options.expiringWithinDays, days < 0 {
			throw ValidationError("--expiring-within-days must be greater than or equal to 0.")
		}
	}
}

struct GlobalOptions: ParsableArguments {
	@Flag(
		name: .shortAndLong,
		help: "Enable verbose output."
	)
	var verbose = false

	@Option(
		name: .long,
		help: "Only include assets expiring within this many days from now."
	)
	var expiringWithinDays: Int?
}

struct AppStoreConnectOptions: ParsableArguments {
	@Option(
		name: .long,
		help: "App Store Connect issuer ID."
	)
	var issuerID: String

	@Option(
		name: .long,
		help: "App Store Connect API key ID."
	)
	var keyID: String

	@Option(
		name: .long,
		help: "Path to the .p8 private key file."
	)
	var privateKeyPath: String
}
