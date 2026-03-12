# AGENTS.md

## Purpose

This repository contains `csa`, a small Ruby CLI for querying Apple Developer / App Store Connect certificate resources exposed by Apple's APIs and reporting certificate/profile expiration state.

The tool is packaged as a gem and primarily runs as:

```bash
bundle exec bin/csa
```

`mise` also exposes it as a task:

```bash
mise run csa
```

## Repo layout

- `bin/csa` - executable entrypoint
- `csa.rb` - compatibility entrypoint that delegates to `lib/csa`
- `lib/csa.rb` - top-level requires and warning filter activation
- `lib/csa/cli.rb` - argument parsing, orchestration, exit codes
- `lib/csa/config.rb` - env/flag resolution and include-filter validation
- `lib/csa/connect_client.rb` - `spaceship` token creation and API fetches
- `lib/csa/filtering.rb` - asset/type/status filtering and profile sorting
- `lib/csa/time_utils.rb` - datetime parsing, expiration math, formatting
- `lib/csa/record_normalizer.rb` - converts Spaceship objects to hashes and redacts large content blobs
- `lib/csa/renderers/table_renderer.rb` - terminal-table output with ANSI color for expired/expiring rows
- `lib/csa/renderers/json_renderer.rb` - JSON output
- `scripts/` - small maintenance scripts used by `mise` / `hk`

## Execution flow

Normal path:

1. `bin/csa`
2. `require_relative '../lib/csa'`
3. `CSA::CLI.run(ARGV)`
4. `Config` resolves credentials and filters
5. `ConnectClient#fetch` loads certificates via direct HTTP calls to Apple's `/v1/certificates` endpoint and profiles via `Spaceship::ConnectAPI`
6. `RecordNormalizer` converts API objects to plain hashes
7. `Filtering.apply` narrows rows by status/type/assets
8. Chosen renderer outputs tables or JSON

## Authentication and local data

The CLI reads credentials from flags or environment:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_FILE`

It also auto-detects `AuthKey_<KEY_ID>.p8` in the current working directory if `ASC_KEY_ID` is provided and no explicit key file is set.

Your local checkout may include `.p8` key files in the root. Treat any such files as sensitive. Do not print, move, or modify key contents unless the task explicitly requires it.

`mise.toml` loads `.env` through:

```toml
[env]
_.file = ".env"
```

So `mise run csa` may work without passing flags if local env is configured.

## Behavior notes

- `ConnectClient#fetch` tries App Store Connect first unless `--enterprise` is passed.
- If the first fetch raises, it falls back to enterprise mode via a broad rescue and retries with `in_house: true`.
- Certificate fetching now goes directly against Apple's `/v1/certificates` REST endpoint with the existing JWT, while profiles still come from `Spaceship::ConnectAPI::Profile.all`.
- This direct certificate fetch is intentional: it avoids depending solely on fastlane's current `ConnectAPI::Certificate::CertificateType` list and allows any certificate types Apple returns for the active account mode to flow through.
- Apple's official App Store Connect `CertificateType` documentation currently lists only code-signing and pass-type certificate families; it does not list APNs / Apple Push Services certificate types. Assume APNs certs are unavailable through this API-key-based certificate path unless Apple expands that enum/API.
- Status filtering is computed, not directly returned by Apple:
  - `expired`
  - `expiring_soon` (within 30 days)
  - `invalid` (`profile_state == "INVALID"`)
  - `ok`
- Type filtering is normalized to:
  - `development`
  - `distribution`
- Profiles are sorted by expiration date in filtering.
- Certificates are sorted by expiration date in the table renderer.
- `record_normalizer.rb` strips `certificate_content` and `profile_content`.

## Commands worth using

Bootstrap:

```bash
mise run bootstrap
```

Run the CLI with repo env:

```bash
mise run csa
```

Run the CLI with arguments:

```bash
mise run csa -- --help
bundle exec bin/csa --help
bundle exec bin/csa --json
bundle exec bin/csa --include-assets certificates --include-statuses expired,expiring_soon
```

Important: pass CLI flags to the `mise` task with `--`, for example `mise run csa -- --help`. `mise run csa --help` addresses `mise` itself, not the underlying CLI. `bundle exec bin/csa ...` also works directly.

Checks / formatting:

```bash
mise run check
mise run fix
```

Use `mise run check` after any change to verify the repo is still clean. If formatting or lint autofixes are needed, run `mise run fix` and then rerun `mise run check`.

## Optional local tools

If these tools are available locally and would help with the task, prefer using them:

- `ast-grep` - structural code search/refactoring; especially useful for non-trivial Ruby refactors where regex would be brittle
- `difftastic` / `delta` - easier diff review when understanding or checking changes
- `shellcheck` - already part of repo checks, but still useful directly when iterating on shell scripts
- `sd` - simpler search/replace than raw `sed` for safe text substitutions
- `yq` - useful for inspecting or updating YAML such as GitHub Actions/workflow files
- `comby` - structural-ish search/replace when `ast-grep` is not the right fit
- `hyperfine` - benchmark command variants if performance comparisons matter
- `scc` - quick codebase shape/language stats when project sizing is useful

If one of these would clearly improve accuracy or speed for the task but is not installed yet, mention that it would be beneficial to install it.

## Validation notes

There is currently no `spec/` or `test/` directory in the repo.

For behavioral validation, prefer:

```bash
bundle exec bin/csa --help
bundle exec bin/csa --json
```

If credentials are available locally, `mise run csa` is a good smoke test of the default configured path.

## Editing guidance

- Keep changes small and consistent with the current minimal style.
- Prefer updating the existing CLI/config/filtering flow rather than adding parallel abstractions.
- Be careful with output changes: table headings, date formatting, and include-filter semantics are part of the user-facing contract.
- If changing fetch/auth behavior, test both explicit flags and env-based resolution paths.
- If changing filtering, verify both table and JSON output.
