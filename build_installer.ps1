# Build Installer Script
param([string]$Version = "1.2.0")

Write-Host "Building installer..." -ForegroundColor Cyan

# 1. Build the app
Write-Host "Building Windows app..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful" -ForegroundColor Green

# 2. Check Inno Setup
$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "Inno Setup not found!" -ForegroundColor Red
    Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    exit 1
}

# 3. Create directories
$InstallerDir = ".\installer"
$OutputDir = ".\build\installer"
if (-not (Test-Path $InstallerDir)) {
    New-Item -ItemType Directory -Path $InstallerDir | Out-Null
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 4. Build installer
Write-Host "Building installer..." -ForegroundColor Yellow
& $InnoSetupPath "$InstallerDir\setup.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Installer build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Installer built successfully!" -ForegroundColor Green

# 5. Show result
$InstallerFile = Get-ChildItem "$OutputDir\*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($InstallerFile) {
    Write-Host "File: $($InstallerFile.FullName)" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($InstallerFile.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    explorer.exe $OutputDir
}
