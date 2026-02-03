import Configuration
import Foundation
import SystemPackage

public struct CodesignAuditConfig {
	public let path: String
	public let rawContents: String
	public let reader: ConfigReader

	init(path: String, rawContents: String, reader: ConfigReader) {
		self.path = path
		self.rawContents = rawContents
		self.reader = reader
	}
}

public enum CodesignAuditConfigLoader {
	public static func load(from path: String) async throws -> CodesignAuditConfig {
		let rawContents = try String(contentsOfFile: path, encoding: .utf8)
		let provider = try await FileProvider<JSONSnapshot>(filePath: FilePath(path))
		let reader = ConfigReader(provider: provider)

		return CodesignAuditConfig(
			path: path,
			rawContents: rawContents,
			reader: reader
		)
	}
}
