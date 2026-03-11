# csa

`csa` is a Ruby CLI for querying Apple App Store Connect and Enterprise APIs for:
- Certificates exposed by Apple's certificates API
- Provisioning profiles

## Installation

### Local development

```bash
bundle install
bundle exec ruby bin/csa --help
```

### Build/install as a gem

```bash
gem build csa.gemspec
gem install ./csa-*.gem
csa --help
```

## Authentication

Provide App Store Connect API credentials via flags or environment:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_FILE`

The CLI also auto-detects `AuthKey_<KEY_ID>.p8` in the current directory when `ASC_KEY_ID` (or `--api-key-id`) is set.

### How certificate reporting works

Certificate data is fetched directly from Apple's `/v1/certificates` endpoint using the configured API key. By calling Apple's raw certificates endpoint directly instead of relying only on fastlane/`spaceship`'s built-in certificate enums, `csa` reports whatever certificate records Apple actually returns for the authenticated account and selected API mode.

Relevant Apple docs:

- [App Store Connect API: Certificates](https://developer.apple.com/documentation/appstoreconnectapi/certificates)
- [App Store Connect API: CertificateType](https://developer.apple.com/documentation/appstoreconnectapi/certificatetype)
- [Enterprise Program API: Certificates](https://developer.apple.com/documentation/enterpriseprogramapi/certificates)
- [Enterprise Program API: CertificateType](https://developer.apple.com/documentation/enterpriseprogramapi/certificatetype)

### Important limitation: API-visible certificate types

Even with the raw API fetch, `csa` can only report certificate types that Apple exposes through the App Store Connect / Enterprise certificates APIs.

Apple's published `CertificateType` documentation for those APIs currently lists:

- `DEVELOPER_ID_APPLICATION`
- `DEVELOPER_ID_APPLICATION_G2`
- `DEVELOPER_ID_KEXT`
- `DEVELOPER_ID_KEXT_G2`
- `DEVELOPMENT`
- `DISTRIBUTION`
- `IOS_DEVELOPMENT`
- `IOS_DISTRIBUTION`
- `MAC_APP_DEVELOPMENT`
- `MAC_APP_DISTRIBUTION`
- `MAC_INSTALLER_DISTRIBUTION`
- `PASS_TYPE_ID`
- `PASS_TYPE_ID_WITH_NFC`

APNs / Apple Push Services certificate types are not documented there, so they do **not** appear in `csa` output. That is an API limitation, not a local filter and not a `mise run csa` issue.

### Note on `--include-types`

The `--include-types` option is intentionally coarse and currently maps certificates into just two buckets for filtering:

- anything marked `development` is considered `development`
- anything marked with either nothing or something other than `development` is considered `distribution`

This affects filtering behavior only. If you do **not** pass `--include-types`, all certificate records returned by Apple's API are included by default.

## Usage

```bash
csa [options]
```

Environment fallbacks:
- `ASC_KEY_ID` -> `--api-key-id`
- `ASC_ISSUER_ID` -> `--api-issuer-id`
- `ASC_KEY_FILE` -> `--api-key-file`

Authentication:
- `--api-key-id KEY_ID` (env: `ASC_KEY_ID`)
- `--api-issuer-id ISSUER_ID` (env: `ASC_ISSUER_ID`)
- `--api-key-file PATH` (env: `ASC_KEY_FILE`)
- `--api-key-stdin` (read ASC key contents from stdin)

API mode:
- `--enterprise` (force Apple Enterprise API mode and skip App Store Connect first attempt)

Output:
- `--json` (output JSON instead of formatted tables)
- `--include-statuses STATUSES` where `STATUSES` is comma-separated (`expired,expiring_soon,invalid,ok`)
- `--include-types TYPES` where `TYPES` is comma-separated (`development,distribution`)
- `--include-assets ASSETS` where `ASSETS` is comma-separated (`certificates,profiles`)

Misc:
- `-h, --help`
- `-v, --version`

Default include behavior:
- If `--include-statuses` is omitted, all statuses are included.
- If `--include-types` is omitted, all types are included.
- If `--include-assets` is omitted, both certificates and profiles are included.

Examples:

```bash
# Default includes all assets, statuses, and types
csa --json

# Only certificates with a subset of statuses
csa --include-assets certificates --include-statuses expired,expiring_soon

# Profiles only, including distribution profiles
csa --include-assets profiles --include-types distribution

# Force enterprise mode
csa --enterprise

# Pipe API key contents on stdin
cat AuthKey_ABC123XYZ.p8 | csa --api-key-id ABC123XYZ --api-issuer-id 11111111-2222-3333-4444-555555555555 --api-key-stdin
```

## Compatibility notes

- `csa` without include flags returns both certificates and profiles.
- `csa certificates` and `csa profiles` are no longer supported; use `--include-assets` instead.
- `csa.rb` remains as a compatibility entrypoint and delegates to the new CLI.
