# Agents Guide

## Project summary
- Goal: Swift CLI that audits code-signing resources for a specific app or Apple developer profile.
- Target: macOS 13+ Swift Package with an executable target.

## Repo layout
- `src/codesign-audit/Sources/codesign-audit.swift`: CLI entry point.
- `Package.swift`: Swift Package manifest and dependencies.
- `scripts/`: repo maintenance scripts (hk, etc).
- `hk.pkl`, `mise.toml`: tooling and lint/format tasks.

## Common tasks
- Run: `mise run codesign-audit` (alias `mise run run`) or `swift run codesign-audit`
- Build (release): `mise run build` or `swift build --configuration release`
- Clean: `mise run clean`
- Lint/format: `mise run check` / `mise run fix`

## Notes for agents
- Keep changes macOS 13+ compatible (see `Package.swift`).
- Prefer `ArgumentParser` for CLI surfaces and `Noora` for user-facing output.
- Avoid adding new dependencies unless necessary.
- Run commands through `mise` when available (e.g., prefer `mise run build` over direct `swift build`).
- Formatting: prefer tab indentation over spaces unless `.editorconfig` specifies otherwise.
- Code style: favor readability and clarity; prefer full `if` statements over ternaries and avoid overly compact one-liners when multi-line code is clearer.
