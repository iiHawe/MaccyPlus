# Upstream maintenance

## Baseline

- Fork: https://github.com/iiHawe/MaccyPlus, branch `plus`.
- Previous fork revision: `0c5e536`.
- Merged upstream: https://github.com/p0deje/Maccy, branch `master`.
- Upstream revision: `c376789`, dated 2026-09-04, checked 2026-09-22.
- Latest stable upstream tag: `2.7.1` (`eb03eba`). The merged revision also
  includes the six subsequent upstream commits.
- Release tag: `v2.7.1-plus.2` (version 2.7.1, build 64).

## Preserve on every merge

- Multi-selection remains enabled, including Shift+Arrow and Command+click.
  Hover must not replace the existing selection while Command is held, and
  unselected rows must not show a selection number.
- History size `0` means unlimited on both insertion and reload. Positive limits
  apply only to unpinned entries, including the size-one edge case.
- Trim oversized histories in one batch, with one persistence save and shortcut
  refresh. Calling single-item deletion repeatedly can freeze the main thread
  for minutes after restoring or importing a large store.
- Release bundle identifier stays `com.hawe.MaccyPlus`, display name `Maccy+`,
  and storage remains in the existing app container. Do not reset user defaults
  or recreate the user's database to test a merge.
- Single-item automatic paste retains the 100 ms delay after closing the popup.
- Never link the original Sparkle framework or restore its upstream feed.
  Manual update checks open the MaccyPlus GitHub release page.

## Build

Use Xcode 26 or later for the Liquid Glass icon. This release was built with
Xcode 27.0 on macOS 27.0. Swift packages are pinned in the committed
`Maccy.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

```sh
xcodebuild -resolvePackageDependencies -project Maccy.xcodeproj -scheme Maccy \
  -clonedSourcePackagesDirPath build/SourcePackages
./scripts/build-release.sh
```

Outputs are `dist/Maccy+.app`, `dist/MaccyPlus-2.7.1-64.zip`, and its SHA-256 file.
The script performs a clean arm64 and x86_64 build, checks both slices and the
signature, rejects any Sparkle dependency, and packages an ad-hoc signed app.
The package filename includes the build number so fork fixes are distinguishable
from the upstream version. Hardened runtime and library validation remain enabled.
It does not install or launch the user's app and does not perform Apple notarization.

Before publishing, extract the exact ZIP, launch that Release app on macOS, open
its popup and settings, and confirm the process remains running. Signature checks
and Debug tests alone do not establish that a Release app can launch.

## Tests

```sh
xcodebuild test -project Maccy.xcodeproj -scheme Maccy \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/Tests \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -disableAutomaticPackageResolution -only-testing:MaccyTests \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=
```

Debug builds use `com.hawe.MaccyPlus.Debug`. With `enable-testing`, storage is
in memory, preferences use a testing suite, clipboard operations use a private
pasteboard, and notifications are suppressed. UI tests pass their private
pasteboard name through `MACCY_TEST_PASTEBOARD`. The system-paste-to-search UI
case is explicitly skipped because AppKit reads the real clipboard for that
operation. Other UI tests can run with `-only-testing:MaccyUITests`, subject to
macOS automation permissions.

Regression tests cover unlimited history and reload, size one with pins,
recopying a pin at capacity, multi-selection, and title sanitization without
changing original clipboard bytes or pin metadata. Upstream tests cover
duplicate merging, storage cleanup, search, rich clipboard formats, and title
layout sanitization.

The test plan runs each case once so failures are visible rather than retried
automatically. Copy-with-Enter uses the standard Return key. Clipboard fixtures
are numeric so synthesized search works with Arabic and Latin input sources.
The pin UI helper navigates by keyboard and uses the toolbar button, avoiding
layout-dependent synthesis of Option+P. No input-source change is required.

### Verified on 2026-09-22

- 97 unit tests passed with no failures.
- Eight targeted UI tests passed: new copy, search, copy by click, copy by
  Return, Shift+Arrow selection, Command+click selection, pin, and unpin.
- Release build succeeded for arm64 and x86_64 with a macOS 14.0 minimum.
- App signature, fork identity, disabled upstream updates, ZIP integrity, and
  SHA-256 sidecar were verified. These runtime tests used the Debug build on
  Apple Silicon/macOS 27.0, not the initially published Release build.
- Test results and build logs are local under `build/` and are not published.

### Build 63 launch fix

Build 62 passed signature verification but aborted before app startup: the main
executable was ad-hoc signed with hardened runtime, while the still-linked
Sparkle framework had a different Team ID. The crash report recorded a DYLD
library-validation failure. Sparkle was no longer used by the manual updater.

Build 63 removes the package, link dependency, service configuration, and obsolete
Mach lookup exceptions. Packaging now starts from a clean build and removes the
old staging app so deleted frameworks cannot survive a directory merge. Release
signing also omits the development-only `get-task-allow` entitlement.

Verified the exact build 63 ZIP on Apple Silicon/macOS 27.0: the extracted
Release app launched and stayed running, its popup and General/Storage settings
opened, and it quit normally. The same extracted app was then installed and
relaunched from `/Applications/Maccy+.app`; About displayed `2.7.1 (63)`.
Both architecture slices and the strict code signature check passed, with no
Sparkle framework or load command in the packaged app. Intel execution was not
tested on hardware.

### Build 64 large-history startup fix

After importing a store larger than the retention limit, a live process sample
showed the main thread spending all its time in `History.load`, repeated
`History.delete` calls, and `updateUnpinnedShortcuts`. The app stayed alive at
100% of one CPU core while trimming entries individually.

Retention now deletes surplus items as one batch. It removes the affected
decorators and session references with sets, deletes their stored content, saves
once, and refreshes shortcuts once. Single-item deletion uses the same path.
Positive retention limits and the unlimited setting retain their existing meaning.

Validation on 2026-09-22:

- All 23 history tests passed, including size-one, unlimited, pins, duplicate
  merging, content cleanup, and a new large-history reload regression.
- The new fixture loads 3,003 items without a limit, then trims to 999 unpinned
  items plus three pins and reloads again. Trimming took 0.49 seconds in Debug,
  preserved the newest entries and pins, and left no orphaned content.
- The exact Release ZIP was extracted, signature-checked, and installed. Three
  fresh processes were launched with the existing persistent store. The popup,
  About, and settings responded, both intervening quits completed normally, and
  idle CPU returned to 0%. About showed `2.7.1 (64)`.
- The persisted retention setting stayed at 999, the three pins survived, and
  the store passed SQLite's integrity check after quitting and relaunching.

## Future updates

Fetch and compare upstream against the recorded merged revision. Review changes
to history retention, migrations, paste timing, selection, bundle identity, and
updates before merging. Build and test before advancing `plus` or publishing a
new release. Keep generated apps, logs, and test results out of Git.
