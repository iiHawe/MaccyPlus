# Upstream maintenance

## Baseline

- Fork: https://github.com/iiHawe/MaccyPlus, branch `plus`.
- Previous fork revision: `0c5e536`.
- Merged upstream: https://github.com/p0deje/Maccy, branch `master`.
- Upstream revision: `c376789`, dated 2026-09-04, checked 2026-09-22.
- Latest stable upstream tag: `2.7.1` (`eb03eba`). The merged revision also
  includes the six subsequent upstream commits.
- Release tag: `v2.7.1-plus`.

## Preserve on every merge

- Multi-selection remains enabled, including Shift+Arrow and Command+click.
  Hover must not replace the existing selection while Command is held, and
  unselected rows must not show a selection number.
- History size `0` means unlimited on both insertion and reload. Positive limits
  apply only to unpinned entries, including the size-one edge case.
- Release bundle identifier stays `com.hawe.MaccyPlus`, display name `Maccy+`,
  and storage remains in the existing app container. Do not reset user defaults
  or recreate the user's database to test a merge.
- Single-item automatic paste retains the 100 ms delay after closing the popup.
- Never start the original Sparkle updater or restore its upstream feed.
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

Outputs are `dist/Maccy+.app`, `dist/MaccyPlus-2.7.1.zip`, and its SHA-256 file.
The script builds arm64 and x86_64, checks both slices and the signature, and
packages an ad-hoc signed app. It does not install or launch the user's app and
does not perform Apple notarization.

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
  SHA-256 sidecar were verified. Runtime tests ran on Apple Silicon/macOS 27.0.
- Test results and build logs are local under `build/` and are not published.

## Future updates

Fetch and compare upstream against the recorded merged revision. Review changes
to history retention, migrations, paste timing, selection, bundle identity, and
updates before merging. Build and test before advancing `plus` or publishing a
new release. Keep generated apps, logs, and test results out of Git.
