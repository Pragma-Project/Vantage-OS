# Build script for nimos kernel
Write-Host "Building nimos kernel..." -ForegroundColor Green

# Set up environment in WSL and build
wsl -d Ubuntu bash -c @"
export PATH=/home/azt12/.nimble/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd ~/nimos-build
echo '=== Starting build ==='
make target-a
"@

Write-Host "Build complete!" -ForegroundColor Green
Write-Host "ISO location: ~/nimos-build/build/nimos.iso"
