#!/usr/bin/env bash
# Build a release, wrap it in "Markdown Reader.app", install it in /Applications and add it to the Dock.
set -euo pipefail

cd "$(dirname "$0")/.."
name="Markdown Reader"
app="/Applications/$name.app"
version="$(cat VERSION)"
build="$(git rev-list --count HEAD)"

swift build -c release
bin="$(swift build -c release --show-bin-path)"

staging="$(mktemp -d)/$name.app"
mkdir -p "$staging/Contents/MacOS" "$staging/Contents/Resources"
cp "$bin/MarkdownReader" "$staging/Contents/MacOS/"
cp -R "$bin/MarkdownReader_MarkdownReader.bundle" "$staging/Contents/Resources/"

iconset="$(mktemp -d)/AppIcon.iconset"
mkdir "$iconset"
swift scripts/make-icon.swift "$iconset/icon_512x512@2x.png"
for px in 16 32 128 256 512; do
  sips -z $px $px "$iconset/icon_512x512@2x.png" --out "$iconset/icon_${px}x${px}.png" >/dev/null
  sips -z $((px * 2)) $((px * 2)) "$iconset/icon_512x512@2x.png" --out "$iconset/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$staging/Contents/Resources/AppIcon.icns"

cat > "$staging/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$name</string>
  <key>CFBundleDisplayName</key><string>$name</string>
  <key>CFBundleIdentifier</key><string>local.gc.MarkdownReader</string>
  <key>CFBundleExecutable</key><string>MarkdownReader</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key><string>Markdown Document</string>
      <key>CFBundleTypeRole</key><string>Editor</string>
      <key>LSHandlerRank</key><string>Owner</string>
      <key>LSItemContentTypes</key><array><string>net.daringfireball.markdown</string></array>
    </dict>
  </array>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$build</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$staging"

rm -rf "$app"
mv "$staging" "$app"

# Register the app and make it the default for .md files.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
swift - <<'SWIFT'
import AppKit
import UniformTypeIdentifiers
var done = false
NSWorkspace.shared.setDefaultApplication(at: URL(fileURLWithPath: "/Applications/Markdown Reader.app"),
                                         toOpen: UTType("net.daringfireball.markdown")!) { error in
  if let error { print("Could not set default .md app: \(error.localizedDescription)") }
  done = true
}
while !done { RunLoop.main.run(until: Date().addingTimeInterval(0.1)) }
SWIFT

# Add to the Dock once; re-running the script only refreshes the app.
if ! defaults read com.apple.dock persistent-apps | grep -q "$name.app"; then
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file://${app// /%20}/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
  killall Dock
fi

echo "Installed $app"
