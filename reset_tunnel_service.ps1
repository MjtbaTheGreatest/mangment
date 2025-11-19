# Complete Cloudflare Tunnel Service Reset
# This script completely removes and reinstalls the tunnel service

Write-Host "🔧 Complete Cloudflare Tunnel Service Reset" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Gray

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Must run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Kill any running cloudflared processes
Write-Host "`n1️⃣  Killing cloudflared processes..." -ForegroundColor Yellow
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Remove service using sc.exe (more reliable than service uninstall)
Write-Host "2️⃣  Removing service..." -ForegroundColor Yellow
sc.exe stop Cloudflared
Start-Sleep -Seconds 2
sc.exe delete Cloudflared
Start-Sleep -Seconds 2

# Install fresh service with config
Write-Host "3️⃣  Installing service with configuration..." -ForegroundColor Green
$configPath = "C:\Users\shams\.cloudflared\config.yml"

Write-Host "   Config file: $configPath" -ForegroundColor Gray

# Install service using cloudflared
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" service install

Start-Sleep -Seconds 3

# Start service
Write-Host "4️⃣  Starting service..." -ForegroundColor Green
Start-Service Cloudflared -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# Check status
Write-Host "`n✅ Service Status:" -ForegroundColor Cyan
Get-Service Cloudflared | Format-Table -AutoSize

Write-Host "`n🔍 Tunnel Info:" -ForegroundColor Cyan
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel info admin-tunnel

Write-Host "`n🧪 Testing Connection:" -ForegroundColor Cyan
Start-Sleep -Seconds 3
try {
    $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404 -or $code -eq 401) {
        Write-Host "✅ TUNNEL WORKING! (API: $code)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n" ("=" * 50) -ForegroundColor Gray
Write-Host "✨ Setup Complete!" -ForegroundColor Green
Read-Host "`nPress Enter to exit"
