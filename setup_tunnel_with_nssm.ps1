# Setup Cloudflare Tunnel using NSSM
# More reliable than cloudflared's built-in service

Write-Host "🔧 Setting up Cloudflare Tunnel with NSSM" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Must run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$nssmPath = "C:\nssm-2.24\win64\nssm.exe"
$cloudflaredPath = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
$configPath = "C:\Users\shams\.cloudflared\config.yml"
$serviceName = "CloudflareTunnel"

# Check if NSSM exists
if (-not (Test-Path $nssmPath)) {
    Write-Host "❌ NSSM not found at $nssmPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Stop and remove old cloudflared service
Write-Host "`n1️⃣  Removing old Cloudflared service..." -ForegroundColor Yellow
Stop-Service Cloudflared -Force -ErrorAction SilentlyContinue
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

try {
    & $nssmPath stop Cloudflared
    & $nssmPath remove Cloudflared confirm
} catch {}

sc.exe stop Cloudflared 2>$null
sc.exe delete Cloudflared 2>$null
Start-Sleep -Seconds 2

# Remove if CloudflareTunnel service exists
Write-Host "2️⃣  Cleaning up existing CloudflareTunnel service..." -ForegroundColor Yellow
try {
    & $nssmPath stop $serviceName 2>$null
    & $nssmPath remove $serviceName confirm 2>$null
} catch {}
Start-Sleep -Seconds 1

# Install new service with NSSM
Write-Host "3️⃣  Installing CloudflareTunnel service with NSSM..." -ForegroundColor Green
& $nssmPath install $serviceName $cloudflaredPath "tunnel" "run" "--config" $configPath "admin-tunnel"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install service!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configure service
Write-Host "4️⃣  Configuring service..." -ForegroundColor Green
& $nssmPath set $serviceName AppDirectory "C:\Users\shams\.cloudflared"
& $nssmPath set $serviceName DisplayName "Cloudflare Tunnel (admin.taif.digital)"
& $nssmPath set $serviceName Description "Cloudflare Tunnel for admin.taif.digital → localhost:53365"
& $nssmPath set $serviceName Start SERVICE_AUTO_START
& $nssmPath set $serviceName AppStdout "C:\code\my_system\my_system_api\logs\tunnel_output.log"
& $nssmPath set $serviceName AppStderr "C:\code\my_system\my_system_api\logs\tunnel_error.log"
& $nssmPath set $serviceName AppRotateFiles 1
& $nssmPath set $serviceName AppRotateBytes 1048576

# Start service
Write-Host "5️⃣  Starting service..." -ForegroundColor Green
& $nssmPath start $serviceName
Start-Sleep -Seconds 5

# Check status
Write-Host "`n" + ("=" * 60) -ForegroundColor Gray
Write-Host "✅ Service Status:" -ForegroundColor Cyan
Get-Service $serviceName | Format-Table -AutoSize

Write-Host "`n🔍 Tunnel Info:" -ForegroundColor Cyan
Start-Sleep -Seconds 3
& $cloudflaredPath tunnel info admin-tunnel

Write-Host "`n🧪 Testing Connection:" -ForegroundColor Cyan
Start-Sleep -Seconds 2
try {
    $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404 -or $code -eq 401) {
        Write-Host "✅ TUNNEL WORKING! (API returned $code - this is normal)" -ForegroundColor Green
    } elseif ($code -eq 530) {
        Write-Host "⚠️  Still getting 530... waiting a bit more..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        try {
            $response2 = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10
            Write-Host "✅ SUCCESS! Status: $($response2.StatusCode)" -ForegroundColor Green
        } catch {
            $code2 = $_.Exception.Response.StatusCode.value__
            if ($code2 -eq 404 -or $code2 -eq 401) {
                Write-Host "✅ TUNNEL WORKING NOW! (API: $code2)" -ForegroundColor Green
            } else {
                Write-Host "❌ Still failing: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "⚠️  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Gray
Write-Host "✨ Setup Complete!" -ForegroundColor Green
Write-Host "`n📝 Service Name: $serviceName" -ForegroundColor White
Write-Host "🌐 Domain: https://admin.taif.digital" -ForegroundColor White
Write-Host "📊 Logs: C:\code\my_system\my_system_api\logs\tunnel_*.log" -ForegroundColor White
Read-Host "`nPress Enter to exit"
