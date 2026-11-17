#!/bin/bash
set -euo pipefail
demo_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$demo_dir/.." && pwd)"
project_dir="$repo_dir"
if [[ -f "$repo_dir/../config/macos-signing.local.json" ]]; then
    project_dir="$(cd "$repo_dir/.." && pwd)"
fi
cache="$project_dir/build/local-test/swift-surface-demo"
final="$demo_dir/Swift Liquid Surface.app"
[[ ! -L "$final" ]] || { echo 'Refusing symlinked app output.' >&2; exit 1; }
if [[ -e "$final/Contents/MacOS/SwiftLiquidSurface" ]] && /usr/sbin/lsof -t "$final/Contents/MacOS/SwiftLiquidSurface" >/dev/null 2>&1; then
    echo 'Quit Swift Liquid Surface normally before rebuilding.' >&2
    exit 1
fi
mkdir -p "$cache"
stage="$(mktemp -d "$cache/package.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app="$stage/Swift Liquid Surface.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$demo_dir/Info.plist" "$app/Contents/Info.plist"
cp "$demo_dir/Background.metal" "$app/Contents/Resources/"
xcrun swiftc -parse-as-library -swift-version 6 -warnings-as-errors -O \
    -target "$(uname -m)-apple-macosx26.0" -module-cache-path "$cache/modules" \
    "$demo_dir/Surface.swift" -o "$app/Contents/MacOS/SwiftLiquidSurface"
identity="$(python3 - "$project_dir/config/macos-signing.local.json" <<'PY'
import json,os,sys
identity=os.environ.get('CROSSDEMO_SIGNING_IDENTITY')
if not identity:
    identity=json.load(open(sys.argv[1]))['identity']
assert identity and identity != '-', 'Stable development signing required'
print(identity)
PY
)"
codesign --force --sign "$identity" --options runtime --timestamp=none "$app"
codesign --verify --deep --strict "$app"
arguments=(--self-test --evidence-dir "$cache/evidence")
reference="$project_dir/build/local-test/qt-surface-demo/evidence"
if [[ -f "$reference/01-no-refraction.png" && -f "$reference/07-interface.png" ]]; then
    arguments+=(--qt-reference-dir "$reference")
fi
"$app/Contents/MacOS/SwiftLiquidSurface" "${arguments[@]}"
if [[ -d "$final" ]]; then
    codesign --verify --strict "$final"
    codesign --display -r "$stage/previous.req" "$final"
    sed -i '' 's/^designated => //' "$stage/previous.req"
    codesign --verify -R "$stage/previous.req" "$app"
    ditto -c -k --keepParent "$final" "$cache/previous-demo-$(date '+%Y%m%d-%H%M%S').zip"
    rm -rf "$final"
fi
mv "$app" "$final"
codesign --verify --deep --strict "$final"
printf 'Built independent Swift Demo: %s\n' "$final"
