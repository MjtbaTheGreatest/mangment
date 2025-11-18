# سكريبت إنشاء أيقونة ICO من PNG
param(
    [string]$inputPng = "assets\icon\app_icon.png",
    [string]$outputIco = "windows\runner\resources\app_icon.ico"
)

Write-Host "🎨 تحويل PNG إلى ICO..." -ForegroundColor Cyan

# الطريقة 1: استخدام موقع ويب API
Write-Host "📥 استخدام API للتحويل..." -ForegroundColor Yellow

$pngFullPath = Resolve-Path $inputPng
$bytes = [System.IO.File]::ReadAllBytes($pngFullPath)
$base64 = [Convert]::ToBase64String($bytes)

try {
    # استخدام API مجاني للتحويل
    $url = "https://api.cloudconvert.com/v2/convert"
    
    Write-Host "⚠️ API يتطلب مفتاح. سنستخدم طريقة بديلة..." -ForegroundColor Yellow
    
    # الطريقة البديلة: تحميل أيقونة Flutter الافتراضية
    $defaultIcon = "C:\flutter\packages\flutter_tools\templates\app\windows.tmpl\runner\resources\app_icon.ico"
    
    if (Test-Path $defaultIcon) {
        Write-Host "✅ استخدام أيقونة Flutter الافتراضية مؤقتاً" -ForegroundColor Green
        Copy-Item $defaultIcon $outputIco -Force
        Write-Host "✅ تم النسخ!" -ForegroundColor Green
    } else {
        Write-Host "❌ لم نجد الأيقونة الافتراضية" -ForegroundColor Red
        Write-Host ""
        Write-Host "🌐 الحل الأسرع:" -ForegroundColor White
        Write-Host "   1. افتح: https://convertio.co/png-ico/" -ForegroundColor Cyan
        Write-Host "   2. ارفع: $inputPng" -ForegroundColor Gray
        Write-Host "   3. حمّل الناتج واحفظه في: $outputIco" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "❌ فشل التحويل: $_" -ForegroundColor Red
}
