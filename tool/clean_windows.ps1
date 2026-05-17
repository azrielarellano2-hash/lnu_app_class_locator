# Force-unlock Flutter/Gradle build folders on Windows.
# Usage: powershell -ExecutionPolicy Bypass -File tool\clean_windows.ps1

$ErrorActionPreference = "SilentlyContinue"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Android = Join-Path $Root "android"

Write-Host "Stopping Gradle daemons..."
$jbr = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path $jbr) { $env:JAVA_HOME = $jbr }
Push-Location $Android
& .\gradlew.bat --stop 2>$null
Pop-Location
Start-Sleep -Seconds 2

Write-Host "Clearing read-only flags under $Root ..."
Get-ChildItem -Path $Root -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Attributes = "Normal" }

$targets = @(
    (Join-Path $Root "build"),
    (Join-Path $Root ".dart_tool"),
    (Join-Path $Root "ios\Flutter\ephemeral"),
    (Join-Path $Root "linux\flutter\ephemeral"),
    (Join-Path $Root "macos\Flutter\ephemeral"),
    (Join-Path $Root "windows\flutter\ephemeral")
)

foreach ($path in $targets) {
    if (-not (Test-Path $path)) { continue }
    Write-Host "Removing $path ..."
    cmd /c "rmdir /s /q `"$path`"" 2>$null
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
}

Get-ChildItem -Path $Root -Filter "desktop.ini" -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$nativeLibs = Join-Path $Root "build\app\intermediates\merged_native_libs"
if (Test-Path $nativeLibs) {
    Write-Host "Removing native lib merge cache ..."
    cmd /c "rmdir /s /q `"$nativeLibs`"" 2>$null
}

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
Write-Host ""
Write-Host "If it still fails: close File Explorer under build\, exclude the project"
Write-Host "folder from Windows Defender, then run this script again."
