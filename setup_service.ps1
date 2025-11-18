# Setup Taif Management API as Windows Service
# Run as Administrator

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Taif Management API Service Setup" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Requires Administrator" -ForegroundColor Red
    exit 1
}

$apiPath = "C:\code\my_system\my_system_api"
$serviceName = "TaifManagementAPI"

# Find NSSM
Write-Host "Finding NSSM..." -ForegroundColor Green
$nssmPath = (Get-Command nssm -ErrorAction SilentlyContinue).Source
if (-not $nssmPath) {
    Write-Host "ERROR: NSSM not found. Install: winget install nssm" -ForegroundColor Red
    exit 1
}
Write-Host "OK: NSSM found at: $nssmPath" -ForegroundColor Green

# Find Dart
Write-Host "Finding Dart..." -ForegroundColor Green
$dartPath = (Get-Command dart -ErrorAction SilentlyContinue).Source
if (-not $dartPath) {
    Write-Host "ERROR: Dart not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Dart found at: $dartPath" -ForegroundColor Green
Write-Host ""

# Remove existing service
$existing = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing service..." -ForegroundColor Yellow
    & nssm stop $serviceName 2>$null
    Start-Sleep -Seconds 2
    & nssm remove $serviceName confirm 2>$null
    Start-Sleep -Seconds 2
}

# Create service
Write-Host "Creating service..." -ForegroundColor Green
& nssm install $serviceName $dartPath run bin/server.dart

# Configure service
Write-Host "Configuring service..." -ForegroundColor Green
& nssm set $serviceName AppDirectory $apiPath
& nssm set $serviceName DisplayName "Taif Management API"
& nssm set $serviceName Description "Backend API Server for Taif Management System"
& nssm set $serviceName Start SERVICE_AUTO_START
& nssm set $serviceName AppRestartDelay 5000

# Create logs directory
if (!(Test-Path "$apiPath\logs")) {
    New-Item -ItemType Directory -Path "$apiPath\logs" -Force | Out-Null
}
& nssm set $serviceName AppStdout "$apiPath\logs\output.log"
& nssm set $serviceName AppStderr "$apiPath\logs\error.log"

# Start service
Write-Host "Starting service..." -ForegroundColor Green
& nssm start $serviceName
Start-Sleep -Seconds 3

# Verify
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq 'Running') {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "SUCCESS! API running as Windows Service" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Service Info:" -ForegroundColor White
    Write-Host "  Name: $serviceName" -ForegroundColor Gray
    Write-Host "  Status: Running" -ForegroundColor Green
    Write-Host "  Port: 53365" -ForegroundColor Gray
    Write-Host "  Auto-start: Yes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Test API:" -ForegroundColor White
    Write-Host "  http://localhost:53365" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Logs:" -ForegroundColor White
    Write-Host "  $apiPath\logs\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  Stop: nssm stop $serviceName" -ForegroundColor Gray
    Write-Host "  Start: nssm start $serviceName" -ForegroundColor Gray
    Write-Host "  Restart: nssm restart $serviceName" -ForegroundColor Gray
    Write-Host "  Status: nssm status $serviceName" -ForegroundColor Gray
    Write-Host ""
    
    # Test connection
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:53365" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "OK: API responding!" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: API not responding yet. Wait a moment..." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "ERROR: Service failed to start" -ForegroundColor Red
    Write-Host "Check logs: $apiPath\logs\" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
