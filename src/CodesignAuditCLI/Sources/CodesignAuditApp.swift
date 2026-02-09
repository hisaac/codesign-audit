import Foundation
import AppStoreConnect_Swift_SDK

struct CodesignAuditApp {
	let options: GlobalOptions
	let apiOptions: AppStoreConnectOptions
	let teamIDs: [String]

	func run() async throws {
		if options.verbose {
			print("Team IDs: \(teamIDs.joined(separator: ", "))")
			print("Issuer ID: \(apiOptions.issuerID)")
			print("Key ID: \(apiOptions.keyID)")
			print("Private Key Path: \(apiOptions.privateKeyPath)")
		}

		let provider = try makeAPIProvider()
		let certificates = try await fetchCertificates(provider: provider)
		let profiles = try await fetchProfiles(provider: provider)
		var certificateAssets = buildCertificateAssets(certificates)
		var profileAssets = buildProfileAssets(profiles)

		if let days = options.expiringWithinDays {
			certificateAssets = filterAssetsExpiringWithinDays(certificateAssets, days: days)
			profileAssets = filterAssetsExpiringWithinDays(profileAssets, days: days)
		}

		print("Certificates (\(certificateAssets.count))")
		printAssets(certificateAssets)
		print("")
		print("Profiles (\(profileAssets.count))")
		printAssets(profileAssets)
	}

	private func makeAPIProvider() throws -> APIProvider {
		let keyURL = URL(fileURLWithPath: apiOptions.privateKeyPath)
		let configuration = try APIConfiguration(
			issuerID: apiOptions.issuerID,
			privateKeyID: apiOptions.keyID,
			privateKeyURL: keyURL
		)
		return APIProvider(configuration: configuration)
	}

	private func fetchCertificates(provider: APIProvider) async throws -> [Certificate] {
		let parameters = APIEndpoint.V1.Certificates.GetParameters(
			fieldsCertificates: [
				.name,
				.displayName,
				.certificateType,
				.expirationDate,
				.serialNumber,
				.platform,
				.activated,
			]
		)
		let request = APIEndpoint.v1.certificates.get(parameters: parameters)
		var certificates: [Certificate] = []

		for try await page in provider.paged(request) {
			certificates.append(contentsOf: page.data)
		}

		return certificates
	}

	private func fetchProfiles(provider: APIProvider) async throws -> [Profile] {
		let parameters = APIEndpoint.V1.Profiles.GetParameters(
			fieldsProfiles: [
				.name,
				.platform,
				.profileType,
				.profileState,
				.uuid,
				.createdDate,
				.expirationDate,
				.bundleID,
				.certificates,
			],
			include: [
				.bundleID,
				.certificates,
			]
		)
		let request = APIEndpoint.v1.profiles.get(parameters: parameters)
		var profiles: [Profile] = []

		for try await page in provider.paged(request) {
			profiles.append(contentsOf: page.data)
		}

		return profiles
	}

	private func buildCertificateAssets(_ certificates: [Certificate]) -> [ExpiringAsset] {
		var assets: [ExpiringAsset] = []
		for certificate in certificates {
			guard let attributes = certificate.attributes else {
				continue
			}

			let displayName = attributes.displayName ?? attributes.name ?? "Unknown Certificate"
			let details = [
				attributes.certificateType?.rawValue ?? "UNKNOWN_TYPE",
				attributes.serialNumber ?? "UNKNOWN_SERIAL",
			].joined(separator: " | ")

			let asset = ExpiringAsset(
				id: certificate.id,
				kind: .certificate,
				name: displayName,
				expirationDate: attributes.expirationDate,
				details: details
			)
			assets.append(asset)
		}

		return assets.sorted(by: ExpiringAsset.sortByExpirationAscending)
	}

	private func buildProfileAssets(_ profiles: [Profile]) -> [ExpiringAsset] {
		var assets: [ExpiringAsset] = []
		for profile in profiles {
			guard let attributes = profile.attributes else {
				continue
			}

			let profileName = attributes.name ?? "Unknown Profile"
			let details = [
				attributes.profileType?.rawValue ?? "UNKNOWN_TYPE",
				attributes.uuid ?? "UNKNOWN_UUID",
			].joined(separator: " | ")

			let asset = ExpiringAsset(
				id: profile.id,
				kind: .profile,
				name: profileName,
				expirationDate: attributes.expirationDate,
				details: details
			)
			assets.append(asset)
		}

		return assets.sorted(by: ExpiringAsset.sortByExpirationAscending)
	}

	private func printAssets(_ assets: [ExpiringAsset]) {
		for asset in assets {
			let expirationDate = AssetOutputFormatter.string(from: asset.expirationDate)
			print("\(expirationDate)\t\(asset.kind.rawValue)\t\(asset.name)\t\(asset.details)")
		}
	}

	private func filterAssetsExpiringWithinDays(_ assets: [ExpiringAsset], days: Int) -> [ExpiringAsset] {
		let now = Date()
		let upperBound = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
		return assets.filter { asset in
			guard let expirationDate = asset.expirationDate else {
				return false
			}
			return expirationDate <= upperBound
		}
	}
}
