# TDLibFramework Teamgram Handoff

## Objective
Deliver TDLib binaries locked to Teamgram-compatible layer 201, expose them via your fork, and update TDLibKit to consume the hosted artifacts. Upstream `main` must stay pristine; all custom work lives on branch `tdlib-teamgram`.

## What’s Done
- Regenerated `builder/tdlib-patches/Python-Apple-Support-patch.patch` from the pristine td submodule; patch now applies cleanly.
- Re-derived `builder/teamgram-patches/td-teamgram.patch` against the current td layout so it patches `td/telegram/*` paths directly.
- Added `scripts/build_platform.sh` helper (checked in) and confirmed macOS + iOS builds with:
  - `./scripts/build_platform.sh macOS`
  - `mise exec tuist -- ./scripts/build_platform.sh iOS`
- Ran `tuist install` via `mise` and generated the workspace (`mise exec tuist -- tuist generate`) to restore iOS/macOS schemes.
- Produced fresh archives: `builder/build/macOS.xcarchive` and `builder/build/iOS.xcarchive`. Logs saved as `build-macos.log`, `build-ios.log`.
- Updated `AGENTS.md` with the “pause on unexpected issues” rule.

## Current Blocker
Git can’t currently update `.git/index` inside this workspace (every attempt to stage hits `fatal: Unable to create .../.git/index.lock: Operation not permitted`). The repository was unpacked with macOS provenance xattrs, and the sandbox refuses writes to `.git`. Resolve by removing the attribute (`xattr -dr com.apple.provenance .git`) or committing from a clean clone.

## Next Steps
1. Clear the `.git` provenance attribute or re-clone so `git add` works, then commit `builder/tdlib-patches/Python-Apple-Support-patch.patch`, `builder/teamgram-patches/td-teamgram.patch`, `scripts/build_platform.sh`, `AGENTS.md`, and the new build logs (if you want to keep them).
2. Push and re-run CI (`gh workflow run CI --repo christophsturm/TDLibFramework --ref tdlib-teamgram`). Verify the patch step now passes.
3. Build remaining matrix targets as needed (`mise exec tuist -- ./scripts/build_platform.sh <platform>`).
4. After CI publishes binaries, update TDLibKit’s `Package.swift` and `versions.json` to consume the hosted artifacts.

## Key Files
- `builder/teamgram-patches/td-teamgram.patch`
- `scripts/build_platform.sh`
- `builder/tdlib-patches/Python-Apple-Support-patch.patch`
- `build-macos.log`, `build-ios.log` (latest local build output)
- `AGENTS.md` (operational note)

## Useful Commands
```bash
# Local rebuild (defaults to macOS)
./scripts/build_platform.sh

# Specific platform rebuild
mise exec tuist -- ./scripts/build_platform.sh iOS

# Trigger CI after fixes
gh workflow run CI --repo christophsturm/TDLibFramework --ref tdlib-teamgram
```
