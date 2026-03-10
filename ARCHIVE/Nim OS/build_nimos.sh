#!/bin/bash
# Build script - run from WSL Ubuntu
export PATH=$PATH:/home/azt12/.nimble/bin

SRCDIR="/mnt/c/Users/azt12/OneDrive/Documents/Code/Nim OS"
BUILDDIR="/home/azt12/nimos-build"

cp "$SRCDIR/kernel.nim" "$BUILDDIR/kernel.nim"
cd "$BUILDDIR"
make 2>&1 | tail -10
cp build/nimos.iso "$SRCDIR/build/nimos.iso"
echo "BUILD_DONE"
