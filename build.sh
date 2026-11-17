#!/bin/bash
set -euo pipefail
demo_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "$demo_dir/." && pwd)"
project_dir="$repo_dir"
if [[ -f "$repo_dir/../config/macos-signing.local.json" ]]; then
    project_dir="$(cd "$repo_dir/.." && pwd)"
fi
cache="$project_dir/build/local-test/qt-glass-demo"
final="$demo_dir/Qt Glass Keyboard.app"
[[ ! -L "$final" ]] || { echo 'Refusing symlinked app output.' >&2; exit 1; }
if [[ -e "$final/Contents/MacOS/QtGlassKeyboard" ]] && /usr/sbin/lsof -t "$final/Contents/MacOS/QtGlassKeyboard" >/dev/null 2>&1; then
    echo 'Quit Qt Glass Keyboard normally before rebuilding.' >&2
    exit 1
fi
identity="$(python3 - "$project_dir/config/macos-signing.local.json" <<'PY'
import json,os,sys
identity=os.environ.get('CROSSDEMO_SIGNING_IDENTITY')
if not identity:
    identity=json.load(open(sys.argv[1]))['identity']
assert identity and identity != '-', 'Stable development signing required'
print(identity)
PY
)"
qt_prefix="$(qtpaths6 --query QT_INSTALL_PREFIX)"
cmake -S "$demo_dir" -B "$cache" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$qt_prefix"
cmake --build "$cache" --parallel 6
ctest --test-dir "$cache" --output-on-failure
stage="$(mktemp -d "$cache/package.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app="$stage/Qt Glass Keyboard.app"
ditto "$cache/QtGlassKeyboard.app" "$app"
plugin_dir="$(qtpaths6 --query QT_INSTALL_PLUGINS)"
mkdir -p "$app/Contents/PlugIns/platforms" "$app/Contents/PlugIns/styles"
ditto "$plugin_dir/platforms/libqcocoa.dylib" "$app/Contents/PlugIns/platforms/libqcocoa.dylib"
ditto "$plugin_dir/styles/libqmacstyle.dylib" "$app/Contents/PlugIns/styles/libqmacstyle.dylib"
# PNG decoding is built into QtGui; this Demo needs only the Cocoa and widget-style plugins.
macdeployqt "$app" -always-overwrite -no-plugins -libpath="$qt_prefix/lib" \
    -executable="$app/Contents/PlugIns/platforms/libqcocoa.dylib" \
    -executable="$app/Contents/PlugIns/styles/libqmacstyle.dylib" -codesign="$identity"
python3 - "$app" <<'PY'
from pathlib import Path
import subprocess, sys
app = Path(sys.argv[1])
for directory in ('MacOS', 'Frameworks', 'PlugIns'):
    for binary in (app / 'Contents' / directory).rglob('*'):
        if not binary.is_file() or binary.is_symlink():
            continue
        if binary.open('rb').read(4) not in (b'\xcf\xfa\xed\xfe', b'\xca\xfe\xba\xbe'):
            continue
        output = subprocess.check_output(['otool', '-L', str(binary)], text=True)
        ids = subprocess.check_output(['otool', '-D', str(binary)], text=True).splitlines()[1:]
        for line in output.splitlines()[1:]:
            dependency = line.strip().split(' (', 1)[0]
            if dependency in ids:
                continue
            assert not dependency.startswith('/opt/homebrew/'), (binary, dependency)
            if dependency.startswith('@rpath/'):
                assert (app / 'Contents/Frameworks' / dependency[7:]).exists(), (binary, dependency)
            elif dependency.startswith('@executable_path/'):
                assert (app / 'Contents/MacOS' / dependency[17:]).exists(), (binary, dependency)
print('PASS: packaged Mach-O dependencies resolve inside the app or system libraries')
PY
codesign --force --sign "$identity" --options runtime --timestamp=none "$app"
codesign --verify --deep --strict "$app"
"$app/Contents/MacOS/QtGlassKeyboard" --self-test
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
printf 'Built independent Qt Demo: %s\n' "$final"
