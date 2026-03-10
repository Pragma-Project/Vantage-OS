# Quick Build Guide

## Prerequisites Check

Before building, verify you have all required tools:

```bash
# Check Nim
nim --version
# Should show: Nim Compiler Version X.Y.Z

# Check GCC
gcc --version
# Should show: gcc (GCC) X.Y.Z

# Check binutils
ld --version
as --version
objcopy --version

# Check xorriso
xorriso --version

# Check Python + Pillow
python --version
python -c "import PIL; print(PIL.__version__)"

# Check git
git --version
```

## Build Environment

### Option 1: WSL (Recommended for Windows)

1. Install WSL2 with Ubuntu:
   ```powershell
   wsl --install
   ```

2. Inside WSL, install tools:
   ```bash
   sudo apt update
   sudo apt install build-essential xorriso git python3-pip
   pip3 install Pillow
   ```

3. Install Nim:
   ```bash
   curl https://nim-lang.org/choosenim/init.sh -sSf | sh
   echo 'export PATH=$HOME/.nimble/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

4. Navigate to project:
   ```bash
   cd "/mnt/c/Users/azt12/OneDrive/Documents/Code/Nim OS"
   ```

5. Build:
   ```bash
   make target-a
   ```

### Option 2: Linux Native

1. Install tools:
   ```bash
   # Debian/Ubuntu
   sudo apt install build-essential xorriso git python3-pip

   # Fedora/RHEL
   sudo dnf install gcc binutils xorriso git python3-pip

   # Arch
   sudo pacman -S base-devel xorriso git python-pip
   ```

2. Install Nim:
   ```bash
   curl https://nim-lang.org/choosenim/init.sh -sSf | sh
   ```

3. Install Pillow:
   ```bash
   pip3 install Pillow
   ```

4. Build:
   ```bash
   make target-a
   ```

### Option 3: macOS

1. Install Homebrew (if not installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install tools:
   ```bash
   brew install gcc binutils xorriso git python
   ```

3. Install Nim:
   ```bash
   curl https://nim-lang.org/choosenim/init.sh -sSf | sh
   ```

4. Install Pillow:
   ```bash
   pip3 install Pillow
   ```

5. Build:
   ```bash
   make target-a
   ```

## Build Commands

### Target A (Terminal Display)

```bash
# Full build from scratch
make target-a

# Output: build/nimos.iso
```

### Target B (Logo Display)

```bash
# 1. Edit kernel.nim
#    Change: const USE_TARGET_A = false

# 2. Build
make target-b

# Output: build/nimos.iso
```

### Clean Build

```bash
# Remove build artifacts
make clean

# Remove build + Limine
make distclean

# Rebuild from scratch
make distclean && make target-a
```

## Build Process Explained

When you run `make target-a`, here's what happens:

1. **Setup Limine** (first time only)
   ```
   git clone limine
   make -C limine
   ```

2. **Compile Nim → C → Object**
   ```
   nim c [flags] kernel.nim → build/kernel_nim.o
   ```

3. **Assemble startup code**
   ```
   as start.S → build/start.o
   ```

4. **Link kernel**
   ```
   ld -T linker.ld start.o kernel_nim.o → build/kernel.elf
   ```

5. **Create ISO structure**
   ```
   mkdir build/iso_root
   cp kernel.elf build/iso_root/
   cp limine files
   ```

6. **Generate ISO image**
   ```
   xorriso -as mkisofs [...] → build/nimos.iso
   ```

7. **Install bootloader**
   ```
   limine/limine bios-install build/nimos.iso
   ```

## Troubleshooting

### "nim: command not found"

Nim not in PATH. Fix:

```bash
# Add to ~/.bashrc or ~/.zshrc:
export PATH=$HOME/.nimble/bin:$PATH

# Then reload:
source ~/.bashrc
```

### "xorriso: command not found"

Install xorriso:

```bash
# Ubuntu/Debian
sudo apt install xorriso

# Fedora
sudo dnf install xorriso

# macOS
brew install xorriso
```

### "No module named 'PIL'"

Install Pillow:

```bash
pip3 install Pillow

# Or with user flag:
pip3 install --user Pillow
```

### "ld: cannot find ..."

Missing binutils. Install:

```bash
# Ubuntu/Debian
sudo apt install binutils

# Fedora
sudo dnf install binutils

# macOS
brew install binutils
# Note: May need to use full path: /usr/local/bin/gld
```

### Nim compilation errors

If you see Nim errors about missing features:

1. Update Nim to latest stable:
   ```bash
   choosenim update stable
   ```

2. Verify Nim version:
   ```bash
   nim --version
   # Should be 2.0+ for best results
   ```

### "make: *** [Makefile:X] Error 1"

Check which step failed:

```bash
# Enable verbose output
make V=1 target-a

# Or run steps manually:
nim c --os:standalone --cpu:amd64 --gc:none --mm:none \
    --threads:off --exceptions:cpp \
    --passC:"-ffreestanding -nostdlib -mno-red-zone -mcmodel=kernel" \
    --passL:"-nostdlib" --noMain:on \
    --nimcache:build/nimcache --out:build/kernel_nim.o \
    kernel.nim
```

## Verifying Build

After successful build:

```bash
# Check ISO exists
ls -lh build/nimos.iso
# Should show: ~5-10 MB file

# Check kernel ELF
file build/kernel.elf
# Should show: ELF 64-bit LSB executable, x86-64

# List kernel sections
readelf -S build/kernel.elf
# Should show: .text, .rodata, .data, .bss

# Check if ISO is bootable
xorriso -indev build/nimos.iso -report_el_torito as_mkisofs
# Should show boot catalog entries
```

## Build Time Expectations

On a typical modern system:

- **First build** (with Limine download): ~2-3 minutes
- **Subsequent builds**: ~10-20 seconds
- **Clean rebuild**: ~15-30 seconds

Breakdown:
- Limine clone + compile: ~90 seconds (once)
- Nim compilation: ~5-10 seconds
- Assembly + linking: <1 second
- ISO creation: ~3-5 seconds

## Next Steps

After successful build:

1. **Locate ISO**:
   ```bash
   ls build/nimos.iso
   ```

2. **Copy to Windows** (if using WSL):
   ```bash
   cp build/nimos.iso /mnt/c/Users/azt12/Desktop/
   ```

3. **Create VMware VM** (see README.md "Running in VMware")

4. **Boot and test**

## Advanced: Manual Build

If you need to build without Make:

```bash
# 1. Setup
mkdir -p build/nimcache
git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1
make -C limine

# 2. Compile Nim
nim c --os:standalone --cpu:amd64 --gc:none --mm:none \
  --threads:off --exceptions:cpp \
  --passC:"-ffreestanding -nostdlib -mno-red-zone -mcmodel=kernel" \
  --passL:"-nostdlib" --noMain:on \
  --nimcache:build/nimcache --out:build/kernel_nim.o \
  kernel.nim

# 3. Assemble
as --64 start.S -o build/start.o

# 4. Link
ld -T linker.ld -nostdlib -o build/kernel.elf \
  build/start.o build/kernel_nim.o

# 5. Create ISO structure
mkdir -p build/iso_root/EFI/BOOT
cp build/kernel.elf build/iso_root/
cp limine.conf build/iso_root/
cp limine/limine-bios.sys build/iso_root/
cp limine/limine-bios-cd.bin build/iso_root/
cp limine/limine-uefi-cd.bin build/iso_root/
cp limine/BOOTX64.EFI build/iso_root/EFI/BOOT/

# 6. Generate ISO
xorriso -as mkisofs \
  -b limine-bios-cd.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --efi-boot limine-uefi-cd.bin \
  -efi-boot-part --efi-boot-image --protective-msdos-label \
  build/iso_root -o build/nimos.iso

# 7. Install bootloader
limine/limine bios-install build/nimos.iso
```

## Build Flags Reference

### Nim Flags

| Flag | Purpose |
|------|---------|
| `--os:standalone` | No OS dependencies |
| `--cpu:amd64` | Target x86_64 architecture |
| `--gc:none` | Disable garbage collector |
| `--mm:none` | Disable memory manager |
| `--threads:off` | Single-threaded kernel |
| `--exceptions:cpp` | C++ exception handling style |
| `--noMain:on` | Don't generate main() wrapper |
| `--nimcache:DIR` | Where to put C intermediates |

### GCC Flags (via --passC)

| Flag | Purpose |
|------|---------|
| `-ffreestanding` | Freestanding environment (no hosted libs) |
| `-nostdlib` | Don't link standard library |
| `-mno-red-zone` | Disable red zone (critical for kernel) |
| `-mcmodel=kernel` | Code model for kernel addressing |
| `-fno-stack-protector` | No stack canaries (no runtime support) |

### Linker Flags

| Flag | Purpose |
|------|---------|
| `-T linker.ld` | Use custom linker script |
| `-nostdlib` | Don't link standard library |

## File Sizes Reference

Expected file sizes after build:

```
kernel.elf       ~200-300 KB   (Nim code + font data)
logo.bin         1,920,000 B   (800×600×4 bytes)
kernel.elf+logo  ~2.1-2.2 MB   (Target B)
nimos.iso        ~5-10 MB      (ISO overhead + bootloader)
```

If sizes are drastically different, something may be wrong.

## Support

If you encounter issues:

1. Check this guide first
2. See README.md "Troubleshooting" section
3. Verify all prerequisites are installed
4. Try clean rebuild: `make distclean && make`
5. Check Nim and GCC versions are reasonably recent
