# Setup Cloudflare Tunnel as Windows Service (without NSSM)
# Uses sc.exe to create a proper Windows service

Write-Host "🔧 Setting up Cloudflare Tunnel Service" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Must run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$cloudflaredPath = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
$configPath = "C:\Users\shams\.cloudflared\config.yml"
$serviceName = "CloudflareTunnel"
$displayName = "Cloudflare Tunnel (admin.taif.digital)"

# Stop any running cloudflared processes
Write-Host "`n1️⃣  Stopping existing cloudflared processes..." -ForegroundColor Yellow
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Remove old services
Write-Host "2️⃣  Removing old services..." -ForegroundColor Yellow
sc.exe stop Cloudflared 2>$null
sc.exe delete Cloudflared 2>$null
sc.exe stop CloudflareTunnel 2>$null
sc.exe delete CloudflareTunnel 2>$null
Start-Sleep -Seconds 2

# Use cloudflared's built-in service install with proper config
Write-Host "3️⃣  Installing service with config..." -ForegroundColor Green
$env:TUNNEL_CONFIG = $configPath

# Run service install as the tunnel run command
& $cloudflaredPath service uninstall 2>$null
Start-Sleep -Seconds 1
& $cloudflaredPath --config $configPath service install

Start-Sleep -Seconds 2

# Start the service
Write-Host "4️⃣  Starting service..." -ForegroundColor Green
Start-Service Cloudflared
Start-Sleep -Seconds 5

# Check status
Write-Host "`n" + ("=" * 60) -ForegroundColor Gray
Write-Host "✅ Service Status:" -ForegroundColor Cyan
Get-Service Cloudflared | Format-Table -AutoSize

Write-Host "`n🔍 Waiting for tunnel connections..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
& $cloudflaredPath tunnel info admin-tunnel

Write-Host "`n🧪 Testing Domain:" -ForegroundColor Cyan
Start-Sleep -Seconds 2
try {
    $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404 -or $code -eq 401) {
        Write-Host "✅ TUNNEL WORKING! (API returned $code)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Status: $code" -ForegroundColor Yellow
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Gray
Write-Host "✨ Setup Complete!" -ForegroundColor Green
Write-Host "`n🌐 Domain: https://admin.taif.digital" -ForegroundColor White
Write-Host "📊 Logs: Use 'Get-EventLog -LogName Application -Source cloudflared -Newest 10'" -ForegroundColor White
Write-Host "`n💡 Service Management:" -ForegroundColor Yellow
Write-Host "   Start:   Start-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Stop:    Stop-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Restart: Restart-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Status:  Get-Service Cloudflared" -ForegroundColor Gray
Read-Host "`nPress Enter to exit"
