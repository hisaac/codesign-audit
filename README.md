# csa

`csa` is a Ruby CLI for querying Apple App Store Connect and Enterprise APIs for:
- Code-signing certificates
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
