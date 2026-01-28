# Firebase Windows SDK Fix Script
# This script helps fix the Firebase Windows build issues

Write-Host "Firebase Windows SDK Fix Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Step 1: Clean build
Write-Host "Step 1: Cleaning build directories..." -ForegroundColor Yellow
flutter clean
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Build cleaned" -ForegroundColor Green
Write-Host ""

# Step 2: Clear pub cache for Firebase packages
Write-Host "Step 2: Clearing Firebase package cache..." -ForegroundColor Yellow
$pubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"
if (Test-Path $pubCache) {
    Get-ChildItem -Path $pubCache -Filter "firebase*" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Firebase cache cleared" -ForegroundColor Green
} else {
    Write-Host "! Pub cache not found at expected location" -ForegroundColor Red
}
Write-Host ""

# Step 3: Get dependencies
Write-Host "Step 3: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencies fetched" -ForegroundColor Green
Write-Host ""

# Step 4: Try building for Windows
Write-Host "Step 4: Attempting Windows build..." -ForegroundColor Yellow
Write-Host "This may take several minutes. Please wait..." -ForegroundColor Cyan
flutter build windows --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Build successful!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✗ Build failed. See errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative solutions:" -ForegroundColor Yellow
    Write-Host "1. Build for Android/iOS instead: flutter run -d <device-id>" -ForegroundColor White
    Write-Host "2. Build for Web: flutter run -d chrome" -ForegroundColor White
    Write-Host "3. Check your internet connection and retry" -ForegroundColor White
    Write-Host "4. Consider disabling Firebase for Windows builds" -ForegroundColor White
}
