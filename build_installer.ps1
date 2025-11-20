# Build Installer Script
# يقوم ببناء البرنامج وإنشاء المثبت

param(
    [string]$Version = "1.2.0"
)

Write-Host "🚀 بدء عملية البناء..." -ForegroundColor Cyan

# 1. بناء البرنامج
Write-Host "`n📦 بناء البرنامج..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ فشل بناء البرنامج" -ForegroundColor Red
    exit 1
}

Write-Host "✅ تم بناء البرنامج بنجاح" -ForegroundColor Green

# 2. التحقق من وجود Inno Setup
$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "❌ Inno Setup غير مثبت!" -ForegroundColor Red
    Write-Host "📥 يمكنك تحميله من: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    exit 1
}

# 3. إنشاء مجلد installer إذا لم يكن موجوداً
$InstallerDir = ".\installer"
if (-not (Test-Path $InstallerDir)) {
    New-Item -ItemType Directory -Path $InstallerDir | Out-Null
}

# 4. إنشاء مجلد build\installer
$OutputDir = ".\build\installer"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# 5. بناء المثبت
Write-Host "`n🔧 بناء المثبت..." -ForegroundColor Yellow
& $InnoSetupPath "$InstallerDir\setup.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ فشل بناء المثبت" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ تم بناء المثبت بنجاح!" -ForegroundColor Green

# 6. Display file info
$InstallerFile = Get-ChildItem "$OutputDir\*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($InstallerFile) {
    Write-Host "`nFile: $($InstallerFile.FullName)" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($InstallerFile.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    
    # Open folder
    Write-Host "`nDone! Open folder? (Y/N)" -ForegroundColor Green
    $response = Read-Host
    if ($response -eq 'Y' -or $response -eq 'y') {
        explorer.exe $OutputDir
    }
}
