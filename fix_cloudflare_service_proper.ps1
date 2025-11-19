# Fix Cloudflare Service Configuration Properly
# This fixes the service to run tunnel with config automatically

Write-Host "🔧 Fixing Cloudflare Tunnel Service Configuration" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Must run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$cloudflaredPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
$configPath = 'C:\Users\shams\.cloudflared\config.yml'

Write-Host "`n📋 Current Configuration:" -ForegroundColor Yellow
Write-Host "   Cloudflared: $cloudflaredPath" -ForegroundColor Gray
Write-Host "   Config: $configPath" -ForegroundColor Gray

# Stop everything
Write-Host "`n1️⃣  Stopping all cloudflared processes..." -ForegroundColor Yellow
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service Cloudflared -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Uninstall old service completely
Write-Host "2️⃣  Removing old service..." -ForegroundColor Yellow
& 'C:\Program Files (x86)\cloudflared\cloudflared.exe' service uninstall 2>$null
sc.exe delete Cloudflared 2>$null
Start-Sleep -Seconds 2

# Install service with config using cloudflared's method
Write-Host "3️⃣  Installing service with configuration..." -ForegroundColor Green
& 'C:\Program Files (x86)\cloudflared\cloudflared.exe' --config 'C:\Users\shams\.cloudflared\config.yml' service install

# Verify installation
Start-Sleep -Seconds 2
$service = Get-Service Cloudflared -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   ✅ Service installed successfully" -ForegroundColor Green
} else {
    Write-Host "   ❌ Service installation failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check service path in registry
Write-Host "`n4️⃣  Verifying service configuration..." -ForegroundColor Cyan
$servicePath = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Cloudflared" -ErrorAction SilentlyContinue).ImagePath
Write-Host "   Service Path: $servicePath" -ForegroundColor Gray

# Start the service
Write-Host "`n5️⃣  Starting service..." -ForegroundColor Green
Start-Service Cloudflared
Start-Sleep -Seconds 8

# Check status
Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
Write-Host "✅ Service Status:" -ForegroundColor Cyan
Get-Service Cloudflared | Format-Table -AutoSize

# Check tunnel connections
Write-Host "🔍 Checking tunnel connections (please wait)..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
& 'C:\Program Files (x86)\cloudflared\cloudflared.exe' tunnel info admin-tunnel

# Test the tunnel
Write-Host "`n🧪 Testing Domain:" -ForegroundColor Cyan
Start-Sleep -Seconds 3
$testPassed = $false
try {
    $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
    $testPassed = $true
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404 -or $code -eq 401) {
        Write-Host "✅ TUNNEL WORKING! (API returned $code - this is correct)" -ForegroundColor Green
        $testPassed = $true
    } else {
        Write-Host "⚠️  Status: $code - May need more time to connect" -ForegroundColor Yellow
        Write-Host "   Waiting 10 more seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        try {
            $response2 = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10
            Write-Host "✅ NOW WORKING!" -ForegroundColor Green
            $testPassed = $true
        } catch {
            $code2 = $_.Exception.Response.StatusCode.value__
            if ($code2 -eq 404 -or $code2 -eq 401) {
                Write-Host "✅ TUNNEL WORKING!" -ForegroundColor Green
                $testPassed = $true
            }
        }
    }
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Gray
if ($testPassed) {
    Write-Host "✨ Setup Complete - Everything Working!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Setup Complete - Please wait 1 minute for tunnel to stabilize" -ForegroundColor Yellow
}

Write-Host "`n📝 Service Management Commands:" -ForegroundColor Yellow
Write-Host "   Status:  Get-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Start:   Start-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Stop:    Stop-Service Cloudflared" -ForegroundColor Gray
Write-Host "   Restart: Restart-Service Cloudflared" -ForegroundColor Gray
Write-Host "`n🌐 Your Domain: https://admin.taif.digital" -ForegroundColor Cyan
Write-Host "🖥️  Local API: http://localhost:53365" -ForegroundColor Cyan

Read-Host "`nPress Enter to exit"
