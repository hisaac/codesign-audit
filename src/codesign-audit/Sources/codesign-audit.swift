import Foundation
import ArgumentParser
import Configuration
import AppStoreConnect_Swift_SDK
import Noora
import SystemPackage

@main
struct codesign_audit: AsyncParsableCommand {
	private enum ASCConfigKeyName {
		static let issuerID = "asc.issuer_id"
		static let keyID = "asc.key_id"
		static let privateKey = "asc.private_key"
		static let privateKeyPath = "asc.private_key_path"
		static let tokenExpiration = "asc.token_expiration"
	}

	private enum ASCEnvVar {
		static let issuerID = "ASC_ISSUER_ID"
		static let keyID = "ASC_KEY_ID"
		static let privateKey = "ASC_PRIVATE_KEY"
		static let privateKeyPath = "ASC_PRIVATE_KEY_PATH"
		static let tokenExpiration = "ASC_TOKEN_EXPIRATION"
	}

	private struct ASCConfig {
		let issuerID: String
		let keyID: String
		let privateKey: String
		let tokenExpiration: String?
	}

	@Option(
		name: .customLong("config"),
		help: "Path to JSON config file. Values in this file are overridden by env vars and CLI args."
	)
	var configPath: String?

	@Option(name: .customLong("asc-issuer-id"), help: "App Store Connect API issuer ID.")
	var ascIssuerID: String?

	@Option(name: .customLong("asc-key-id"), help: "App Store Connect API private key ID.")
	var ascKeyID: String?

	@Option(name: .customLong("asc-private-key"), help: "App Store Connect API private key contents (.p8).")
	var ascPrivateKey: String?

	@Option(
		name: .customLong("asc-private-key-path"),
		help: "Path to App Store Connect API private key (.p8)."
	)
	var ascPrivateKeyPath: String?

	@Option(
		name: .customLong("asc-token-expiration"),
		help: "Optional token expiration duration, forwarded to APIConfiguration."
	)
	var ascTokenExpiration: String?

	mutating func run() async throws {
		let noora = Noora()
		let ascConfig = try await loadASCConfig()
		let message: TerminalText = """
		Loaded App Store Connect credentials for issuer \
		\(.primary(ascConfig.issuerID)) and key \
		\(.primary(ascConfig.keyID)).
		"""
		noora.passthrough(message)
	}

	private func loadASCConfig() async throws -> ASCConfig {
		let providers = try await configurationProviders()
		let config = ConfigReader(providers: providers)
		let issuerID = try config.requiredString(forKey: ConfigKey(ASCConfigKeyName.issuerID))
		let keyID = try config.requiredString(forKey: ConfigKey(ASCConfigKeyName.keyID))
		let privateKey = try resolvePrivateKey(using: config)
		let tokenExpiration = normalizedInput(config.string(forKey: ConfigKey(ASCConfigKeyName.tokenExpiration)))
		return ASCConfig(
			issuerID: issuerID,
			keyID: keyID,
			privateKey: privateKey,
			tokenExpiration: tokenExpiration
		)
	}

	private func configurationProviders() async throws -> [any ConfigProvider] {
		var providers: [any ConfigProvider] = []
		let cliValues = cliConfigValues()
		providers.append(InMemoryProvider(name: "cli", values: cliValues))

		let envValues = environmentConfigValues()
		providers.append(InMemoryProvider(name: "environment", values: envValues))

		if let configPath = normalizedInput(configPath) {
			let expanded = (configPath as NSString).expandingTildeInPath
			let fileProvider = try await FileProvider<JSONSnapshot>(
				filePath: FilePath(expanded)
			)
			providers.append(fileProvider)
		}

		return providers
	}

	private func cliConfigValues() -> [AbsoluteConfigKey: ConfigValue] {
		var values: [AbsoluteConfigKey: ConfigValue] = [:]
		setValue(normalizedInput(ascIssuerID), forKey: ASCConfigKeyName.issuerID, in: &values)
		setValue(normalizedInput(ascKeyID), forKey: ASCConfigKeyName.keyID, in: &values)
		setSecretValue(normalizedInput(ascPrivateKey), forKey: ASCConfigKeyName.privateKey, in: &values)
		setValue(normalizedInput(ascPrivateKeyPath), forKey: ASCConfigKeyName.privateKeyPath, in: &values)
		setValue(normalizedInput(ascTokenExpiration), forKey: ASCConfigKeyName.tokenExpiration, in: &values)
		return values
	}

	private func environmentConfigValues() -> [AbsoluteConfigKey: ConfigValue] {
		var values: [AbsoluteConfigKey: ConfigValue] = [:]
		let env = ProcessInfo.processInfo.environment
		setValue(normalizedInput(env[ASCEnvVar.issuerID]), forKey: ASCConfigKeyName.issuerID, in: &values)
		setValue(normalizedInput(env[ASCEnvVar.keyID]), forKey: ASCConfigKeyName.keyID, in: &values)
		setSecretValue(normalizedInput(env[ASCEnvVar.privateKey]), forKey: ASCConfigKeyName.privateKey, in: &values)
		setValue(normalizedInput(env[ASCEnvVar.privateKeyPath]), forKey: ASCConfigKeyName.privateKeyPath, in: &values)
		setValue(normalizedInput(env[ASCEnvVar.tokenExpiration]), forKey: ASCConfigKeyName.tokenExpiration, in: &values)
		return values
	}

	private func resolvePrivateKey(using config: ConfigReader) throws -> String {
		if let pathValue = normalizedInput(config.string(forKey: ConfigKey(ASCConfigKeyName.privateKeyPath))) {
			let expanded = (pathValue as NSString).expandingTildeInPath
			do {
				return try String(contentsOfFile: expanded, encoding: .utf8)
			} catch {
				throw ValidationError("Failed to read ASC private key file at \(expanded).")
			}
		}

		if let privateKey = normalizedInput(
			try? config.requiredString(forKey: ConfigKey(ASCConfigKeyName.privateKey), isSecret: true)
		) {
			return privateKey
		}

		throw ValidationError("Missing ASC private key. Provide --asc-private-key, --asc-private-key-path, or ASC_PRIVATE_KEY/ASC_PRIVATE_KEY_PATH.")
	}

	private func normalizedInput(_ value: String?) -> String? {
		guard let value else {
			return nil
		}
		if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return nil
		}
		return value
	}

	private func setValue(
		_ value: String?,
		forKey keyName: String,
		in values: inout [AbsoluteConfigKey: ConfigValue]
	) {
		guard let value else {
			return
		}
		values[absoluteKey(keyName)] = ConfigValue(.string(value), isSecret: false)
	}

	private func setSecretValue(
		_ value: String?,
		forKey keyName: String,
		in values: inout [AbsoluteConfigKey: ConfigValue]
	) {
		guard let value else {
			return
		}
		values[absoluteKey(keyName)] = ConfigValue(.string(value), isSecret: true)
	}

	private func absoluteKey(_ name: String) -> AbsoluteConfigKey {
		AbsoluteConfigKey(ConfigKey(name))
	}
}
