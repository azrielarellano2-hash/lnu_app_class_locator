# Fixes common Windows Flutter/Android build failures:
# - read-only asset folders (AccessDeniedException on mergeDebugAssets)
# - desktop.ini / Thumbs.db polluting Gradle intermediates
#
# Usage (from project root):
#   powershell -ExecutionPolicy Bypass -File tool\fix_windows_build.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host "Clearing read-only flags under assets and build..."
cmd /c "attrib -R assets /S /D" | Out-Null
if (Test-Path build) {
  cmd /c "attrib -R build /S /D" | Out-Null
}

Write-Host "Removing desktop.ini and Thumbs.db..."
Get-ChildItem -Path $root -Recurse -Force -Include desktop.ini,Thumbs.db -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\\.pub-cache\\' } |
  Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "Stopping Gradle daemons (releases file locks)..."
if (Test-Path "android\gradlew.bat") {
  Push-Location android
  & .\gradlew.bat --stop 2>$null
  Pop-Location
}

Write-Host "Running flutter clean..."
flutter clean

if (Test-Path build) {
  Write-Host "Removing build folder..."
  Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
}

Write-Host "Done. Close Android Studio/emulators if clean failed, then run: flutter pub get && flutter run"
