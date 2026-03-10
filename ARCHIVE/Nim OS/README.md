# nimos - Minimal x86_64 Nim OS Kernel

A minimal bare-metal x86_64 kernel written in Nim, bootable via Limine bootloader on VMware.

## Project Structure

```
Nim OS/
├── kernel.nim          # Main Nim kernel code
├── start.S             # Assembly bootstrap
├── linker.ld           # Linker script (higher-half)
├── limine.conf         # Bootloader configuration
├── Makefile            # Build system
├── convert_logo.py     # PNG to binary converter
├── logo.png            # Logo image (for Target B)
├── README.md           # This file
└── build/              # Build output (created by make)
    ├── kernel.elf      # Compiled kernel
    └── nimos.iso       # Bootable ISO
```

## Features

### Target A: Terminal-like Display
- Framebuffer graphics using Limine protocol
- 8x16 bitmap font rendering
- Text output primitives (putPixel, putChar, writeString)
- Displays boot message with title and prompt

### Target B: Logo Display
- Converts PNG logo to raw pixel buffer
- Embeds image data directly into kernel
- Displays 800x600 logo on boot

## Prerequisites

### Required Tools

1. **Nim compiler** (latest stable)
   ```bash
   # Install from https://nim-lang.org/install.html
   nim --version
   ```

2. **GNU toolchain** (GCC, binutils)
   ```bash
   # On Linux/WSL:
   sudo apt install build-essential

   # Verify:
   gcc --version
   ld --version
   as --version
   ```

3. **xorriso** (ISO creation)
   ```bash
   # On Linux/WSL:
   sudo apt install xorriso

   # Verify:
   xorriso --version
   ```

4. **Python 3** with Pillow (for logo conversion)
   ```bash
   pip install Pillow
   ```

5. **Git** (for fetching Limine)
   ```bash
   git --version
   ```

### VMware Setup

- VMware Workstation/Player (Windows/Linux)
- OR VMware Fusion (macOS)

## Building

### Build Target A (Terminal Display)

```bash
# Ensure kernel.nim has: const USE_TARGET_A = true
make target-a
```

This will:
1. Download and build Limine bootloader (first run only)
2. Compile Nim kernel code
3. Assemble startup code
4. Link kernel ELF binary
5. Create bootable ISO at `build/nimos.iso`

### Build Target B (Logo Display)

```bash
# 1. Edit kernel.nim, change to: const USE_TARGET_A = false

# 2. Build
make target-b
```

This will:
1. Convert `logo.png` to `logo.bin` (800x600 ARGB)
2. Embed logo data into kernel
3. Build and package ISO

### Manual Logo Conversion

If you need to convert the logo manually:

```bash
python convert_logo.py
```

This reads `logo.png` and creates `logo.bin`:
- Input: PNG image (any size)
- Output: 800x600 raw pixel buffer
- Format: ARGB (0xAARRGGBB), 4 bytes per pixel, little-endian
- Size: 800 × 600 × 4 = 1,920,000 bytes

## Running in VMware

### Create VM

1. Open VMware, click "Create a New Virtual Machine"

2. Configuration:
   - **Guest OS Type**: Other → Other 64-bit
   - **Firmware**: UEFI (recommended) or BIOS (both work)
   - **Memory**: 512 MB minimum (1 GB recommended)
   - **Hard Disk**: Remove/skip (not needed)
   - **Network**: Disable (not needed)

3. Edit VM settings → CD/DVD:
   - ✓ Use ISO image
   - Browse to: `build/nimos.iso`
   - ✓ Connect at power on

4. Boot Order:
   - Ensure CD-ROM is first boot device
   - May need to enter BIOS/UEFI setup on first boot (F2/Del)

### Power On

Click "Power On" - you should see:

**Target A**:
- Dark blue background (color: 0x001030)
- Green text at top: "nimos. (VMware test)"
- White text below: "ready>"

**Target B**:
- Your logo image displayed at coordinates (0, 0)
- Top-left aligned, 800x600 pixels

### Troubleshooting

**Black screen / no output**:
- Check VM firmware settings (try switching UEFI ↔ BIOS)
- Verify ISO is attached and connected
- Check boot order in BIOS/UEFI

**"No bootable device" error**:
- ISO may not be properly attached
- Boot order may prioritize hard disk
- Try rebuilding ISO: `make clean && make`

**Kernel panic / hangs**:
- Check serial/debug output if available
- Verify Nim compiler version compatibility
- Try rebuilding Limine: `make distclean && make`

## Technical Details

### Nim Compilation

The kernel uses freestanding Nim with these critical flags:

```nim
nim c --os:standalone --cpu:amd64 --gc:none --mm:none \
  --threads:off --exceptions:cpp \
  --passC:"-ffreestanding -nostdlib -mno-red-zone -mcmodel=kernel" \
  --passL:"-nostdlib" \
  --noMain:on
```

**Key points**:
- `--os:standalone`: No OS dependencies
- `--gc:none --mm:none`: No garbage collection or memory management
- `--threads:off`: Single-threaded
- `-mno-red-zone`: Critical for x86_64 kernel (protects stack red zone)
- `-mcmodel=kernel`: Required for higher-half addressing

### Memory Layout

```
0xFFFFFFFF80000000  <- Kernel base (higher-half)
0xFFFFFFFF80200000  <- Kernel code start (.text)
  ...
  .text    (code)
  .rodata  (constants, font data)
  .data    (initialized data, embedded logo)
  .bss     (zero-initialized, stack)
```

### Limine Protocol

The kernel uses Limine's framebuffer request structure:

```nim
type LimineFramebufferRequest = object
  id: array[4, uint64]      # Magic identifier
  revision: uint64           # Protocol version
  response: ptr Response     # Filled by bootloader
```

The bootloader populates the response with:
- Framebuffer base address (physical memory)
- Width, height, pitch (bytes per line)
- Pixel format (bits per pixel, RGB masks)

### Font Rendering

Embedded 8×16 bitmap font (ASCII 32-126):
- 95 characters × 16 bytes = 1520 bytes
- Each byte = one row of 8 pixels
- Bit set = foreground color, clear = background

### Logo Embedding

Target B uses GNU ld's binary embedding:

```bash
# Convert binary to object file
objcopy -I binary -O elf64-x86-64 \
  --rename-section .data=.logo \
  logo.bin logo.o

# Link with kernel (symbols: _binary_logo_bin_start/end)
ld ... kernel.o logo.o -o kernel.elf
```

The linker script places `.logo` section at known address.

## Makefile Targets

```bash
make target-a       # Build Target A (terminal)
make target-b       # Build Target B (logo)
make iso            # Create bootable ISO
make convert-logo   # Run PNG to BIN conversion
make clean          # Remove build artifacts
make distclean      # Remove build + Limine
make run-vmware     # Show VMware setup instructions
```

## Code Organization

### kernel.nim

- **Limine structures**: C-ABI compatible types for bootloader protocol
- **Runtime support**: Minimal compiler runtime (no stdlib, no GC)
- **Graphics primitives**: `putPixel()`, `clearScreen()`
- **Font rendering**: `putChar()`, `writeString()` with embedded font
- **Target A**: Terminal display with text
- **Target B**: Logo blitting from embedded data

### start.S

- Assembly bootstrap code
- Sets up stack pointer
- Calls Nim `kmain()`
- Halts if main returns

### linker.ld

- Higher-half kernel layout (0xFFFFFFFF80000000)
- Section alignment (4KB pages)
- Logo data placement
- Symbol definitions for embedded binaries

## VMware-Specific Notes

### Firmware Choice

- **UEFI**: Modern, recommended, faster boot
- **BIOS**: Legacy, wider compatibility

Both work with Limine. If one fails, try the other.

### Display Settings

- VM video memory: 16 MB minimum (default is fine)
- 3D acceleration: Not needed (can be disabled)
- Resolution: Limine will use best available mode
  - Target A: Any resolution works (draws text at fixed position)
  - Target B: Assumes ≥800×600 framebuffer

### Performance

Expected boot time:
- BIOS: ~2-3 seconds
- UEFI: ~1-2 seconds
- Kernel execution: <100ms (basically instant)

Kernel just draws and halts - no ongoing processing.

## Development Tips

### Switching Targets

Edit `kernel.nim`, line ~330:

```nim
# For terminal display:
const USE_TARGET_A = true

# For logo display:
const USE_TARGET_A = false
```

Then rebuild:
```bash
make clean
make target-a  # or target-b
```

### Adding More Text (Target A)

```nim
proc targetA() =
  initFramebuffer()
  clearScreen(0xFF001030)  # Dark blue

  # Add more text:
  writeString(20, 100, "Hello from Nim!", 0xFFFFFF00, 0xFF001030)
  writeString(20, 120, "Kernel is running", 0xFF00FF00, 0xFF001030)

  # Halt
  while true:
    asm "cli; hlt"
```

### Changing Colors

Colors are 32-bit ARGB:
- `0xAARRGGBB`
- `0xFF` = opaque alpha (usually want this)

Examples:
- `0xFFFF0000` - Red
- `0xFF00FF00` - Green
- `0xFF0000FF` - Blue
- `0xFFFFFF00` - Yellow
- `0xFF00FFFF` - Cyan
- `0xFFFF00FF` - Magenta
- `0xFFFFFFFF` - White
- `0xFF000000` - Black

### Using Different Logo

Replace `logo.png` with your image, then:

```bash
make convert-logo
make target-b
```

Image will be automatically resized to 800×600.

For different sizes, edit `convert_logo.py`:

```python
TARGET_WIDTH = 1024   # Change resolution
TARGET_HEIGHT = 768

# Also update kernel.nim:
const LOGO_WIDTH = 1024
const LOGO_HEIGHT = 768
```

## License

Public domain / CC0. Use as you wish.

## Acknowledgments

- **Limine**: Modern bootloader protocol (https://github.com/limine-bootloader/limine)
- **Nim**: Systems programming language (https://nim-lang.org)
- **OSDev Wiki**: Invaluable resource (https://wiki.osdev.org)
