param([Parameter(Mandatory = $true)][string]$QtRoot)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$original = Join-Path $repo '单界面液态玻璃'
$source = Join-Path $repo 'build/windows-source'
$build = Join-Path $repo 'build/windows'
$bundle = Join-Path $repo 'dist/windows'
$evidence = Join-Path $repo 'build/windows-evidence'

# Qt's Windows command-line QML tools can misread non-ASCII source paths.
New-Item -ItemType Directory -Force $source | Out-Null
Get-ChildItem -LiteralPath $original -File | Copy-Item -Destination $source -Force

cmake -S $source -B $build -G 'Visual Studio 17 2022' -A x64 "-DCMAKE_PREFIX_PATH=$QtRoot" -DCMAKE_CONFIGURATION_TYPES=Release
if ($LASTEXITCODE -ne 0) { throw 'CMake configuration failed' }
cmake --build $build --config Release --parallel 2
if ($LASTEXITCODE -ne 0) { throw 'Release build failed' }
ctest --test-dir $build -C Release --output-on-failure --timeout 40
if ($LASTEXITCODE -ne 0) { throw 'Build-tree shader checks failed' }

New-Item -ItemType Directory -Force $bundle, $evidence | Out-Null
Copy-Item (Join-Path $build 'Release/QtLiquidSurface.exe') $bundle -Force
$exe = Join-Path $bundle 'QtLiquidSurface.exe'
& (Join-Path $QtRoot 'bin/windeployqt.exe') --release --qmldir $source --dir $bundle --compiler-runtime $exe
if ($LASTEXITCODE -ne 0) { throw 'Qt/QML deployment failed' }

# Include the redistributable DLLs app-locally so testing needs no VS/Qt installation.
$vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or !$vs) { throw 'Visual C++ runtime location not found' }
$crt = Get-ChildItem "$vs/VC/Redist/MSVC/*/x64/Microsoft.VC143.CRT" -Directory |
    Sort-Object FullName -Descending | Select-Object -First 1
if (!$crt) { throw 'Microsoft.VC143.CRT redistributables not found' }
Copy-Item (Join-Path $crt.FullName '*.dll') $bundle -Force

foreach ($required in @('Qt6Core.dll', 'Qt6Gui.dll', 'Qt6Qml.dll', 'Qt6Quick.dll',
        'platforms/qwindows.dll', 'qml/QtQuick/qmldir', 'vcruntime140.dll', 'msvcp140.dll')) {
    if (!(Test-Path (Join-Path $bundle $required))) { throw "Missing portable dependency: $required" }
}
Copy-Item (Join-Path $repo 'WINDOWS-README.txt') (Join-Path $bundle 'README.txt') -Force
Copy-Item (Join-Path $repo 'THIRD-PARTY-NOTICES.md') $bundle -Force
@"
Repository: https://github.com/jsnjjnzx/CrossDemo
Commit: $env:GITHUB_SHA
Qt: 6.11.1, MSVC 2022 x64 Release
CI check: Direct3D 11 WARP; physical GPU appearance/performance awaits user testing.
"@ | Set-Content (Join-Path $bundle 'BUILD-INFO.txt') -Encoding utf8

# Test deployment without the Qt SDK's PATH, plugin or QML search directories.
$env:PATH = (($env:PATH -split ';') | Where-Object {
    $_ -and !($_.StartsWith($QtRoot, [StringComparison]::OrdinalIgnoreCase))
}) -join ';'
foreach ($name in @('QT_PLUGIN_PATH', 'QT_QPA_PLATFORM_PLUGIN_PATH', 'QML2_IMPORT_PATH', 'QML_IMPORT_PATH')) {
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}
$stdout = Join-Path $evidence 'portable-stdout.txt'
$stderr = Join-Path $evidence 'portable-stderr.txt'
$process = Start-Process -FilePath $exe -ArgumentList @('--self-test', '--render-dir', "`"$evidence`"") `
    -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
if (!$process.WaitForExit(45000)) {
    $process.Kill()
    throw 'Portable shader check exceeded 45 seconds'
}
$process.Refresh()
Get-Content $stdout, $stderr
if ($process.ExitCode -ne 0) { throw "Portable shader check failed: $($process.ExitCode)" }
if (!((Get-Content $stdout, $stderr -Raw) -match 'PASS.*GPU checks')) {
    throw 'Portable renderer did not report a completed GPU check'
}
Write-Output 'PASS: portable application checked with SDK search paths removed'
