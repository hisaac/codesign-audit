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
csa [list] [options]
csa certificates [options]
csa profiles [options]
```

Commands:
- `list`: show both certificates and profiles (default)
- `certificates`: only certificates
- `profiles`: only profiles

Options:
- `--api-key-id KEY_ID`
- `--api-issuer-id ISSUER_ID`
- `--api-key-file PATH`
- `--api-key-stdin` (read ASC key contents from stdin)
- `--in-house`
- `--json`
- `--filter TYPES` where `TYPES` is comma-separated (`error,warn,ok`)
- `--exclude-development`
- `-h, --help`
- `-v, --version`

Examples:

```bash
# Default command is "list"
csa --json

# Explicit command
csa certificates --filter error,warn

# Profiles only, excluding development profiles
csa profiles --exclude-development

# Force enterprise mode
csa list --in-house

# Pipe API key contents on stdin
cat AuthKey_ABC123XYZ.p8 | csa list --api-key-id ABC123XYZ --api-issuer-id 11111111-2222-3333-4444-555555555555 --api-key-stdin
```

## Backward compatibility

Legacy behavior is preserved:
- `csa` without a command still returns both certificates and profiles.
- `csa certificates` and `csa profiles` continue to work.
- `csa.rb` remains as a compatibility entrypoint and delegates to the new CLI.
