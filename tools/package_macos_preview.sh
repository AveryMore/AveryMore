#!/bin/bash
# Explicitly unnotarized preview for GitHub Releases; signed releases use package_macos_release.sh.
set -euo pipefail
AIE_PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
AIE_RELEASE="${AIE_RELEASE:-0.1.0}"
AIE_ARCH_VALUE="${AIE_ARCH:-$(uname -m)}"
case "$AIE_RELEASE" in *[!a-zA-Z0-9.-]*|'') echo 'Invalid release version' >&2; exit 2;; esac
case "$AIE_ARCH_VALUE" in arm64|x86_64) ;; *) echo 'Unsupported architecture' >&2; exit 2;; esac
if [ "${AIE_SKIP_BUILD:-0}" != 1 ]; then bash "$AIE_PROJECT/apps/macos/AIEPopup/build.sh"; fi
AIE_APP="$AIE_PROJECT/apps/macos/AIEPopup/build/AI Everything.app"
AIE_OUTPUT="$AIE_PROJECT/apps/macos/AIEPopup/build/releases"
mkdir -p "$AIE_OUTPUT"
AIE_STAGE="$(mktemp -d "$AIE_OUTPUT/.preview.XXXXXX")"
trap 'rm -rf "$AIE_STAGE"' EXIT
ditto --noextattr --norsrc "$AIE_APP" "$AIE_STAGE/AI Everything.app"
codesign --verify --deep --strict "$AIE_STAGE/AI Everything.app"
ln -s /Applications "$AIE_STAGE/Applications"
AIE_DMG="$AIE_OUTPUT/AI-Everything-$AIE_RELEASE-$AIE_ARCH_VALUE.dmg"
hdiutil create -volname 'AI Everything' -srcfolder "$AIE_STAGE" -ov -format "${AIE_DMG_FORMAT:-ULMO}" -fs HFS+ "$AIE_DMG"
hdiutil verify "$AIE_DMG"
(cd "$AIE_OUTPUT" && LC_ALL=C shasum -a 256 "$(basename "$AIE_DMG")" > SHA256SUMS)
echo "未公证版本：$AIE_DMG"
