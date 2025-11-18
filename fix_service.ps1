# Fix and restart API service

Write-Host "Fixing service configuration..." -ForegroundColor Yellow

$serviceName = "TaifManagementAPI"
$apiPath = "C:\code\my_system\my_system_api"
$dartExe = "C:\flutter\bin\cache\dart-sdk\bin\dart.exe"

# Check if dart.exe exists
if (Test-Path $dartExe) {
    Write-Host "Using Dart executable: $dartExe" -ForegroundColor Green
} else {
    Write-Host "ERROR: Dart executable not found at $dartExe" -ForegroundColor Red
    exit 1
}

# Stop service
Write-Host "Stopping service..." -ForegroundColor Yellow
nssm stop $serviceName

# Update to use dart.exe instead of dart.bat
Write-Host "Updating service configuration..." -ForegroundColor Green
nssm set $serviceName Application $dartExe
nssm set $serviceName AppParameters "run bin/server.dart"
nssm set $serviceName AppDirectory $apiPath

# Start service
Write-Host "Starting service..." -ForegroundColor Green
nssm start $serviceName

Start-Sleep -Seconds 3

# Check status
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host ""
    Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Yellow'})
    
    if ($service.Status -eq 'Running') {
        Write-Host "SUCCESS! API is running" -ForegroundColor Green
        
        # Test connection
        Start-Sleep -Seconds 2
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:53365" -Method GET -TimeoutSec 5 -ErrorAction Stop
            Write-Host "API responding on port 53365" -ForegroundColor Green
        } catch {
            Write-Host "WARNING: API not responding yet" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Service status: $($service.Status)" -ForegroundColor Yellow
        Write-Host "Check logs at: $apiPath\logs\" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Commands:" -ForegroundColor White
Write-Host "  Check status: nssm status $serviceName" -ForegroundColor Gray
Write-Host "  View logs: Get-Content $apiPath\logs\error.log -Tail 20" -ForegroundColor Gray
Write-Host "  Restart: nssm restart $serviceName" -ForegroundColor Gray
Write-Host ""
