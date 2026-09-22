#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build dist

xcodebuild clean build \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build/Release \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -disableAutomaticPackageResolution \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  > build/release-build.log 2>&1

app='build/Release/Build/Products/Release/Maccy.app'
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist")
archive="MaccyPlus-${version}-${build}.zip"
codesign --verify --deep --strict "$app"
architectures=$(lipo -archs "$app/Contents/MacOS/Maccy")
[[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]]
# The fork uses manual updates. Linking the signed upstream framework into our
# ad-hoc hardened-runtime app aborts at launch because their Team IDs differ.
dependencies=$(otool -L "$app/Contents/MacOS/Maccy")
if [[ -d "$app/Contents/Frameworks/Sparkle.framework" || "$dependencies" == *Sparkle.framework* ]]; then
  printf 'Unexpected Sparkle dependency in the release app.\n' >&2
  exit 1
fi
# ditto merges directories, so an old package must not retain removed libraries.
rm -rf 'dist/Maccy+.app'
ditto "$app" 'dist/Maccy+.app'
codesign --verify --deep --strict 'dist/Maccy+.app'
ditto -c -k --sequesterRsrc --keepParent 'dist/Maccy+.app' "dist/$archive"
(cd dist && shasum -a 256 "$archive" > "$archive.sha256")
printf 'Built %s/dist/%s\n' "$PWD" "$archive"
