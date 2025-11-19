# Fix Cloudflare Tunnel Service Configuration
# This script fixes the cloudflared service to run with proper config

Write-Host "🔧 Fixing Cloudflare Tunnel Service..." -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Stop the service
Write-Host "⏸️  Stopping Cloudflared service..." -ForegroundColor Yellow
Stop-Service Cloudflared -Force -ErrorAction SilentlyContinue
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Uninstall current service
Write-Host "🗑️  Uninstalling old service..." -ForegroundColor Yellow
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" service uninstall

# Install service with proper config
Write-Host "📦 Installing service with config..." -ForegroundColor Green
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" service install

# Start the service
Write-Host "▶️  Starting Cloudflared service..." -ForegroundColor Green
Start-Service Cloudflared
Start-Sleep -Seconds 5

# Check status
Write-Host "`n✅ Service Status:" -ForegroundColor Green
Get-Service Cloudflared | Format-Table -AutoSize

Write-Host "`n🔍 Checking tunnel connections..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
& "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel info admin-tunnel

Write-Host "`n🧪 Testing domain..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Domain is working! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 404 -or $statusCode -eq 401) {
        Write-Host "✅ Tunnel is working! (API returned $statusCode - this is normal)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Domain returned: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n✨ Done!" -ForegroundColor Green
Read-Host "`nPress Enter to exit"
