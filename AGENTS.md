# TDLibFramework Agent Notes

- `main` on `github.com/christophsturm/TDLibFramework` now carries all Teamgram customizations. `upstream_main` tracks the pristine upstream `main` for easy rebases.
- Core modifications live in `builder/teamgram-patches/td-teamgram.patch`, `scripts/build_platform.sh`, and the Swift smoke tests `test_teamgram.swift` / `test_teamgram_auth.swift`.
- CI workflow `CI` runs on every push to `main` and on tags. Each green run publishes `TDLibFramework.zip` as a GitHub release tagged `<TDLib version>-<td commit>`.
- Local rebuilds should start from a clean `td` submodule: `./scripts/build_platform.sh <platform>` resets, reapplies patches, and rebuilds OpenSSL/TDLib.
- If anything unexpected blocks progress (missing tooling, permissions, etc.), pause immediately and ask for direction—never work around surprises silently.

## Releasing for TDLibKit

1. Push the desired change set to `main` (or create a git tag). CI will rebuild the entire matrix and publish a release automatically.
2. Copy the checksum from the release notes (CI logs it automatically) or recompute with `swift package compute-checksum TDLibFramework.zip` if you need to verify locally.
3. Update TDLibKit’s `Package.swift` and `versions.json` to point at the new release URL and checksum, then push those changes.

## Quick Commands

```bash
# Local rebuild (defaults to macOS)
./scripts/build_platform.sh

# Run Teamgram auth smoke test
swift test_teamgram_auth.swift

# Trigger CI manually (optional)
gh workflow run CI --repo christophsturm/TDLibFramework --ref main
```
