# سكريبت لإعادة تشغيل السيرفر
Write-Host "🔄 إيقاف السيرفر القديم..." -ForegroundColor Yellow

# البحث عن العمليات على المنفذ 53365
$connections = netstat -ano | findstr "53365"
if ($connections) {
    Write-Host "📌 وجدت عمليات على المنفذ 53365:" -ForegroundColor Cyan
    Write-Host $connections
    
    # استخراج PID
    $connections -split "`n" | ForEach-Object {
        if ($_ -match '\s+(\d+)\s*$') {
            $pid = $matches[1]
            Write-Host "⚠️  إيقاف العملية PID: $pid" -ForegroundColor Red
            try {
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                Write-Host "✅ تم إيقاف العملية $pid" -ForegroundColor Green
            } catch {
                Write-Host "❌ فشل إيقاف العملية $pid - قد تحتاج صلاحيات مدير" -ForegroundColor Red
                Write-Host "💡 جرب: taskkill /F /PID $pid من PowerShell بصلاحيات مدير" -ForegroundColor Yellow
            }
        }
    }
}

# انتظار قليلاً
Start-Sleep -Seconds 2

# التحقق من أن المنفذ أصبح متاحاً
$stillRunning = netstat -ano | findstr "53365"
if ($stillRunning) {
    Write-Host "" 
    Write-Host "❌ المنفذ لا يزال مستخدماً!" -ForegroundColor Red
    Write-Host "📋 الحل اليدوي:" -ForegroundColor Yellow
    Write-Host "   1. افتح Task Manager (Ctrl+Shift+Esc)" -ForegroundColor White
    Write-Host "   2. ابحث عن عملية 'dart.exe'" -ForegroundColor White
    Write-Host "   3. اضغط عليها بالزر الأيمن واختر 'End Task'" -ForegroundColor White
    Write-Host "   4. أعد تشغيل هذا السكريبت" -ForegroundColor White
    Write-Host ""
    Read-Host "اضغط Enter بعد إيقاف العملية يدوياً"
}

Write-Host ""
Write-Host "🚀 تشغيل السيرفر الجديد..." -ForegroundColor Green

# الانتقال للمجلد الصحيح
Set-Location "C:\code\my_system\my_system_api\bin"

# تشغيل السيرفر
Write-Host "📂 المسار: $(Get-Location)" -ForegroundColor Cyan
Write-Host "▶️  تنفيذ: dart run server.dart" -ForegroundColor Cyan
Write-Host ""

dart run server.dart
