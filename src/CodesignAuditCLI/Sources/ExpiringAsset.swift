import Foundation

struct ExpiringAsset {
	enum Kind: String {
		case certificate = "CERTIFICATE"
		case profile = "PROFILE"
	}

	let id: String
	let kind: Kind
	let name: String
	let expirationDate: Date?
	let details: String

	static func sortByExpirationAscending(lhs: ExpiringAsset, rhs: ExpiringAsset) -> Bool {
		switch (lhs.expirationDate, rhs.expirationDate) {
		case let (left?, right?):
			if left != right {
				return left < right
			}
		case (.some, .none):
			return true
		case (.none, .some):
			return false
		case (.none, .none):
			break
		}

		if lhs.kind != rhs.kind {
			return lhs.kind.rawValue < rhs.kind.rawValue
		}

		if lhs.name != rhs.name {
			return lhs.name < rhs.name
		}

		return lhs.id < rhs.id
	}
}

enum AssetOutputFormatter {
	private static let formatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
		return formatter
	}()

	static func string(from date: Date?) -> String {
		guard let date else {
			return "NO_EXPIRATION"
		}
		return formatter.string(from: date)
	}
}
