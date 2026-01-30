# codesign-audit

Swift CLI that audits code-signing resources for a specific app or Apple developer profile.

## Run

```sh
mise run run -- --config ./config.example.json
```

## Configuration

The App Store Connect credentials can be provided via:

1. CLI args
2. Environment variables
3. JSON config file

Priority is listed above (CLI overrides env, env overrides file).

### CLI args

```sh
swift run codesign-audit \
  --asc-issuer-id YOUR_ISSUER_ID \
  --asc-key-id YOUR_KEY_ID \
  --asc-private-key-path /path/to/AuthKey_ABC123.p8 \
  --asc-token-expiration 1200
```

### Environment variables

```sh
export ASC_ISSUER_ID=YOUR_ISSUER_ID
export ASC_KEY_ID=YOUR_KEY_ID
export ASC_PRIVATE_KEY_PATH=/path/to/AuthKey_ABC123.p8
# or: export ASC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
export ASC_TOKEN_EXPIRATION=1200
```

### JSON config file

See `config.example.json` for the expected shape. Use `--config` to provide the path.
