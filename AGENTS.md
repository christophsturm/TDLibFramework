# TDLibFramework Agent Notes

- Work happens on branch `tdlib-teamgram` in fork `github.com/christophsturm/TDLibFramework`; upstream `main` stays untouched.
- Core customizations live in `builder/teamgram-patches/td-teamgram.patch`, `scripts/build_platform.sh`, plus Swift smoke tests `test_teamgram.swift` and `test_teamgram_auth.swift`.
- CI (workflow `CI`) currently fails because `builder/tdlib-patches/Python-Apple-Support-patch.patch` no longer applies; fix by replacing it with cleanly patched sources or committing the patched files and dropping the patch step.
- Once CI passes, publish the XCFramework via `create-release`, capture the download URL + checksum, then update TDLibKit’s `Package.swift` and `versions.json` to pull the hosted binary.
- Local rebuilds should start from a clean `td` submodule: the helper `./scripts/build_platform.sh [platform]` resets, reapplies patches, and rebuilds OpenSSL/TDLib.
- If anything unexpected blocks progress (for example, a missing external tool such as Tuist), pause immediately, let the user know, and wait for direction—never work around surprises silently.

## Quick Commands

```bash
# Local rebuild (defaults to macOS)
./scripts/build_platform.sh

# Run Teamgram auth smoke test
swift test_teamgram_auth.swift

# Trigger CI on the fork
gh workflow run CI --repo christophsturm/TDLibFramework --ref tdlib-teamgram
```
