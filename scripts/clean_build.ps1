# Clears Flutter/Android build output when Gradle clean fails on Windows
# (locked files, desktop.ini junk, or paths longer than 260 characters).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    $root = (Get-Location).Path
}

$build = Join-Path $root 'build'
$androidBuild = Join-Path $root 'android\app\build'
$empty = Join-Path $root '.empty_tmp'

function Remove-TreeLong([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    $long = if ($path.StartsWith('\\?\')) { $path } else { "\\?\$($path.TrimEnd('\'))" }
    try {
        Remove-Item -LiteralPath $long -Recurse -Force -ErrorAction Stop
    }
    catch {
        New-Item -ItemType Directory -Force -Path $empty | Out-Null
        robocopy $empty $path /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        Remove-Item -LiteralPath $long -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $empty -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Removing Windows desktop.ini / Thumbs.db files..."
Get-ChildItem -Path $root -Include 'desktop.ini', 'Thumbs.db' -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "Stopping Gradle/Java processes..."
Get-Process -Name 'java' -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Stopping Java PID $($_.Id)"
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

$gradlew = Join-Path $root 'android\gradlew.bat'
if ((Test-Path $gradlew) -and $env:JAVA_HOME) {
    Push-Location (Join-Path $root 'android')
    & .\gradlew.bat --stop 2>$null
    Pop-Location
}

Start-Sleep -Seconds 2

Write-Host "Removing build folders..."
Remove-TreeLong $build
Remove-TreeLong $androidBuild

Push-Location $root
flutter clean
flutter pub get
Pop-Location

Write-Host "Done. Run: flutter run"
