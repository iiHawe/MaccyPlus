#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p build dist

xcodebuild build \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build/Release \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -disableAutomaticPackageResolution \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  > build/release-build.log 2>&1

app='build/Release/Build/Products/Release/Maccy.app'
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
archive="MaccyPlus-${version}.zip"
codesign --verify --deep --strict "$app"
architectures=$(lipo -archs "$app/Contents/MacOS/Maccy")
[[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]]
ditto "$app" 'dist/Maccy+.app'
ditto -c -k --sequesterRsrc --keepParent 'dist/Maccy+.app' "dist/$archive"
(cd dist && shasum -a 256 "$archive" > "$archive.sha256")
printf 'Built %s/dist/%s\n' "$PWD" "$archive"
