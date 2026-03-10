# nimos Quick Start Guide

Get your Nim kernel booting in VMware in 15 minutes!

## TL;DR

```bash
# For Windows users with WSL:
# 1. Open PowerShell and run:
wsl

# 2. Navigate to project:
cd "/mnt/c/Users/azt12/OneDrive/Documents/Code/Nim OS"

# 3. Build:
make target-a

# 4. Boot in VMware:
#    - Create new VM (Other 64-bit, UEFI)
#    - Attach build/nimos.iso to CD/DVD
#    - Power on
```

## Prerequisites (5 minutes)

### Windows (WSL)

```powershell
# Install WSL (if not already installed):
wsl --install

# Restart computer, then in WSL:
sudo apt update
sudo apt install build-essential xorriso git python3-pip
pip3 install Pillow
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
echo 'export PATH=$HOME/.nimble/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Linux

```bash
# Ubuntu/Debian:
sudo apt install build-essential xorriso git python3-pip

# Install Nim:
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
echo 'export PATH=$HOME/.nimble/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install Pillow:
pip3 install Pillow
```

### macOS

```bash
brew install gcc binutils xorriso git python
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
echo 'export PATH=$HOME/.nimble/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
pip3 install Pillow
```

## Build (2 minutes)

```bash
# Navigate to project
cd "C:\Users\azt12\OneDrive\Documents\Code\Nim OS"  # Windows (in WSL)
# or
cd "/path/to/Nim OS"  # Linux/macOS

# Build Target A (terminal display)
make target-a

# Output: build/nimos.iso (~5-10 MB)
```

## VMware Setup (5 minutes)

### Create VM

1. VMware → **Create New Virtual Machine**
2. Guest OS: **Other → Other 64-bit**
3. Firmware: **UEFI** (or BIOS)
4. Memory: **1024 MB**
5. Remove hard disk (not needed)

### Attach ISO

1. Edit VM settings → **CD/DVD**
2. ✓ **Use ISO image**: Browse to `build/nimos.iso`
3. ✓ **Connect at power on**

### Boot

1. **Power on VM**
2. Wait 1-3 seconds
3. See kernel output!

## Expected Output

**Target A**:
```
┌───────────────────────────────────┐
│                                   │
│  nimos. (VMware test)             │  <- Green
│                                   │
│  ready>                           │  <- White
│                                   │
│  [Dark blue background]           │
└───────────────────────────────────┘
```

**Success!** Your Nim kernel is running!

## What Next?

### Try Target B (Logo Display)

```bash
# 1. Convert logo
make convert-logo

# 2. Edit kernel.nim, change line ~330:
const USE_TARGET_A = false  # Was: true

# 3. Rebuild
make clean
make target-b

# 4. Reboot VM (it auto-reloads ISO)
```

You should see your logo.png displayed on screen!

### Modify the Kernel

**Change text color** (kernel.nim, line ~350):

```nim
# Green title
writeString(20, 20, "nimos. (VMware test)", 0xFF00FF00, 0xFF001030)

# Change to red:
writeString(20, 20, "nimos. (VMware test)", 0xFFFF0000, 0xFF001030)
#                                             ^^^^ Red
```

**Add more text**:

```nim
proc targetA() =
  initFramebuffer()
  clearScreen(0xFF001030)

  writeString(20, 20, "nimos. (VMware test)", 0xFF00FF00, 0xFF001030)
  writeString(20, 60, "ready>", 0xFFFFFFFF, 0xFF001030)

  # Add new line:
  writeString(20, 100, "Hello from Nim!", 0xFFFFFF00, 0xFF001030)

  while true:
    asm "cli; hlt"
```

**Rebuild and test**:

```bash
make clean
make target-a
# Power on VM
```

### Change background color

```nim
# kernel.nim, line ~346
clearScreen(0xFF001030)  # Dark blue

# Try different colors:
clearScreen(0xFF000000)  # Black
clearScreen(0xFF101010)  # Dark grey
clearScreen(0xFF003030)  # Dark red
clearScreen(0xFF002020)  # Dark green
clearScreen(0xFF4B0082)  # Indigo
```

Colors are 32-bit ARGB: `0xAARRGGBB`

## Common Issues

### "nim: command not found"

```bash
# Nim not in PATH. Run:
source ~/.bashrc  # or ~/.zshrc on macOS

# Verify:
nim --version
```

### "No bootable device" in VMware

- ISO not attached or not connected at power on
- Check VM settings → CD/DVD → Connected checkbox
- Verify ISO path is correct

### Black screen in VMware

- Boot order may be wrong
- Enter BIOS/UEFI setup (press F2 during boot)
- Set CD-ROM as first boot device
- Save and exit (F10)

### Build errors

```bash
# Clean rebuild:
make clean
make target-a

# If still fails:
make distclean  # Removes Limine too
make target-a   # Re-downloads and rebuilds everything
```

## File Overview

| File | Purpose |
|------|---------|
| `kernel.nim` | Main kernel code (edit this!) |
| `start.S` | Assembly bootstrap (rarely need to touch) |
| `linker.ld` | Linker script (advanced) |
| `limine.conf` | Bootloader config (can customize menu) |
| `Makefile` | Build system (use `make` commands) |
| `convert_logo.py` | PNG → binary converter |
| `logo.png` | Your logo image (replace with own) |
| `README.md` | Full documentation |
| `BUILD.md` | Detailed build instructions |
| `VMWARE.md` | VMware setup guide |
| `QUICKSTART.md` | This file |

## Build Commands

```bash
make target-a       # Build terminal display
make target-b       # Build logo display
make clean          # Clean build artifacts
make distclean      # Clean + remove Limine
make convert-logo   # Convert logo.png to logo.bin
make run-vmware     # Show VMware instructions
```

## Typical Workflow

```bash
# 1. Edit kernel.nim
vim kernel.nim

# 2. Rebuild
make clean && make target-a

# 3. Test in VMware
# (Just power on VM - it reloads ISO automatically)

# 4. Repeat
```

**Tip**: Keep build terminal and VMware window side-by-side for rapid iteration.

## Learning Resources

### Next Steps

1. **Add keyboard input**
   - Read PS/2 controller
   - Handle scan codes
   - Echo characters to screen

2. **Add more graphics**
   - Draw rectangles, circles
   - Load multiple images
   - Simple animations

3. **Add interrupts**
   - Set up IDT (Interrupt Descriptor Table)
   - Handle timer interrupt (PIT)
   - Keyboard interrupt

4. **Add memory management**
   - Parse Limine memory map
   - Implement page allocator
   - Virtual memory (paging)

### Resources

- **OSDev Wiki**: https://wiki.osdev.org
  - Comprehensive OS development resource
  - Tutorials, reference, community

- **Limine Protocol**: https://github.com/limine-bootloader/limine/blob/trunk/PROTOCOL.md
  - How to use Limine features
  - Memory map, framebuffer, modules, etc.

- **Nim Manual**: https://nim-lang.org/docs/manual.html
  - Nim language reference
  - Bare-metal programming tips

- **Intel SDM**: https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html
  - x86_64 architecture reference
  - Detailed CPU documentation

## Examples

### Custom Boot Message

```nim
proc targetA() =
  initFramebuffer()
  clearScreen(0xFF000000)  # Black background

  var y = 20
  writeString(20, y, "================================", 0xFF00FF00, 0xFF000000)
  y += 20
  writeString(20, y, "  WELCOME TO MY NIM OS!", 0xFFFFFF00, 0xFF000000)
  y += 20
  writeString(20, y, "================================", 0xFF00FF00, 0xFF000000)
  y += 40
  writeString(20, y, "System ready.", 0xFFFFFFFF, 0xFF000000)
  y += 20
  writeString(20, y, "Kernel version: 0.1.0", 0xFF888888, 0xFF000000)

  while true:
    asm "cli; hlt"
```

### Simple Pixel Art

```nim
proc drawBox(x, y, width, height: int, color: uint32) =
  for py in y..<(y + height):
    for px in x..<(x + width):
      putPixel(px, py, color)

proc targetA() =
  initFramebuffer()
  clearScreen(0xFF001030)

  # Draw colorful boxes
  drawBox(100, 100, 50, 50, 0xFFFF0000)  # Red
  drawBox(160, 100, 50, 50, 0xFF00FF00)  # Green
  drawBox(220, 100, 50, 50, 0xFF0000FF)  # Blue

  writeString(20, 20, "Pixel Art Demo", 0xFFFFFFFF, 0xFF001030)

  while true:
    asm "cli; hlt"
```

### Color Gradient

```nim
proc targetA() =
  initFramebuffer()

  # Draw horizontal gradient
  let width = fb.width.int
  let height = fb.height.int

  for y in 0..<height:
    for x in 0..<width:
      let r = (x * 255) div width
      let g = (y * 255) div height
      let b = 128
      let color = 0xFF000000'u32 or (r.uint32 shl 16) or (g.uint32 shl 8) or b.uint32
      putPixel(x, y, color)

  writeString(20, 20, "Gradient Demo", 0xFF000000, 0xFFFFFFFF)

  while true:
    asm "cli; hlt"
```

## Tips

### Fast Rebuild

```bash
# Don't need to rebuild Limine every time:
make clean      # Removes kernel only
make target-a   # Fast rebuild

# Only use this if Limine is broken:
make distclean  # Removes everything including Limine
make target-a   # Slow rebuild (re-downloads Limine)
```

### Debugging

Add debug output:

```nim
proc targetA() =
  initFramebuffer()
  clearScreen(0xFF001030)

  # Debug: show framebuffer info
  var y = 20
  writeString(20, y, "Width:", 0xFFFFFFFF, 0xFF001030)
  y += 20
  # Note: Converting numbers to strings requires more work
  # For now, just verify you reach each line with text

  writeString(20, y, "FB initialized OK", 0xFF00FF00, 0xFF001030)
```

### Faster Workflow

**Terminal 1** (build):
```bash
# Watch and rebuild on changes:
while true; do
  make clean && make target-a
  sleep 1
done
```

**Terminal 2** (VMware):
- Keep VM window open
- Power on/off to test new builds

## Help

Stuck? Check these in order:

1. **This file** (you are here)
2. **README.md** - Full documentation
3. **BUILD.md** - Build troubleshooting
4. **VMWARE.md** - VMware-specific issues

Still stuck? Check:
- Nim version: `nim --version` (should be 2.0+)
- GCC version: `gcc --version` (should be 7.0+)
- ISO exists: `ls -lh build/nimos.iso` (should be ~5-10 MB)

## Success Checklist

- [ ] Prerequisites installed (Nim, GCC, xorriso, etc.)
- [ ] `make target-a` completes without errors
- [ ] `build/nimos.iso` exists (~5-10 MB)
- [ ] VMware VM created (Other 64-bit, UEFI)
- [ ] ISO attached to CD/DVD, connected at power on
- [ ] VM boots and shows kernel output
- [ ] Can modify kernel.nim and see changes after rebuild

All checked? **Congratulations!** You have a working Nim kernel development environment!

## What You've Accomplished

You now have:
- ✓ A bare-metal x86_64 kernel written in Nim
- ✓ Bootable via modern UEFI or legacy BIOS
- ✓ Direct framebuffer graphics access
- ✓ Text rendering with embedded font
- ✓ Image display capability
- ✓ Complete build system
- ✓ VMware test environment

This is a solid foundation for OS development. Have fun building!
