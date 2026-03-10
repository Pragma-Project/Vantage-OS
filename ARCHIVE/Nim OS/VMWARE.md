# VMware Setup Guide for nimos

This guide covers setting up and running the nimos kernel in VMware Workstation/Player.

## Prerequisites

- VMware Workstation (Windows/Linux) or VMware Player (free)
- OR VMware Fusion (macOS)
- Built ISO file: `build/nimos.iso`

## VM Creation

### Step 1: Create New Virtual Machine

1. Open VMware
2. Click **"Create a New Virtual Machine"**
3. Choose **"Custom (advanced)"** (recommended) or **"Typical"**

### Step 2: Hardware Compatibility

- **Workstation**: Select latest available version
- **Player/Fusion**: Use default

Click **Next**.

### Step 3: Installation Media

Select: **"I will install the operating system later"**

Click **Next**.

### Step 4: Guest Operating System

- **Guest OS**: Select **"Other"**
- **Version**: Select **"Other 64-bit"**

This is important! Don't select Linux, Windows, or any specific OS.

Click **Next**.

### Step 5: VM Name and Location

- **Name**: `nimos` (or whatever you prefer)
- **Location**: Default is fine, or choose custom path

Click **Next**.

### Step 6: Firmware Type

**CRITICAL CHOICE**:

- **UEFI** (Recommended)
  - Modern firmware
  - Faster boot
  - Better graphics initialization
  - If you see this option, choose it

- **BIOS** (Legacy)
  - Older firmware
  - Wider compatibility
  - Also works fine

Both work with Limine. If unsure, choose **UEFI**.

Click **Next**.

### Step 7: Processor Configuration

- **Number of processors**: 1
- **Cores per processor**: 1

(Kernel is single-threaded, more won't help)

Click **Next**.

### Step 8: Memory

- **Minimum**: 512 MB
- **Recommended**: 1024 MB (1 GB)
- **Maximum**: Any (kernel only uses ~2 MB)

Set slider to **1024 MB**.

Click **Next**.

### Step 9: Network

Select: **"Do not use a network connection"**

(Kernel has no network stack)

Click **Next**.

### Step 10: I/O Controller

Use default: **"LSI Logic SAS"** (recommended)

Click **Next**.

### Step 11: Virtual Disk

Select: **"Create a new virtual disk"**

Click **Next**.

### Step 12: Disk Type

Use default: **"SCSI"** (recommended)

Click **Next**.

### Step 13: Disk Size

Set to: **1 GB** (minimum allowed)

- Select: **"Store virtual disk as a single file"**
- Uncheck: **"Allocate all disk space now"** (to save space)

**IMPORTANT**: We'll remove this disk in the next section!

Click **Next**.

### Step 14: Disk File

Use default name: `nimos.vmdk`

Click **Next**.

### Step 15: Finish

Review settings and click **Finish**.

## VM Configuration

Before booting, configure the VM:

### Remove Hard Disk (Not Needed)

1. Right-click VM → **Edit virtual machine settings**
2. Select **"Hard Disk (SCSI)"**
3. Click **Remove**
4. Confirm removal

This saves disk space since kernel doesn't use it.

### Attach ISO to CD/DVD

1. In VM settings, select **"CD/DVD (SATA)"**

2. Select: **"Use ISO image file"**

3. Click **Browse** and navigate to:
   ```
   C:\Users\azt12\OneDrive\Documents\Code\Nim OS\build\nimos.iso
   ```

4. **CRITICAL**: Check **"Connect at power on"**

5. Click **OK**

### Configure Boot Order

#### For UEFI firmware:

1. Power on VM
2. Quickly press **F2** to enter EFI setup
3. Navigate to **Boot** tab
4. Ensure **CD-ROM Drive** is first in boot order
5. Press **F10** to save and exit

#### For BIOS firmware:

1. Power on VM
2. Quickly press **F2** or **Del** to enter BIOS setup
3. Navigate to **Boot** tab
4. Move **CD-ROM Drive** to top of boot order
5. Press **F10** to save and exit

**Tip**: If you miss the timing, restart VM and try again.

### Optional: Video Settings

For better display (optional):

1. Edit VM settings → **Display**
2. Set **Video memory**: 16 MB (or higher)
3. Uncheck **"Accelerate 3D graphics"** (not needed)
4. Graphics memory: Default

## Booting the Kernel

### First Boot

1. Power on the VM (click green play button)

2. You should see:
   - VMware logo
   - Limine bootloader (may flash briefly)
   - **Your kernel!**

### Expected Output

**Target A (Terminal)**:
```
Dark blue background (RGB: 0, 16, 48)

┌─────────────────────────────────────────┐
│                                         │
│  nimos. (VMware test)                   │  <- Green text
│                                         │
│  ready>                                 │  <- White text
│                                         │
│  [cursor/black screen below]            │
│                                         │
└─────────────────────────────────────────┘
```

**Target B (Logo)**:
```
Your logo.png displayed at top-left corner
Rest of screen: black or previous framebuffer contents
Image size: 800×600 pixels
```

### Boot Time

- UEFI: ~1-2 seconds from power on to kernel display
- BIOS: ~2-3 seconds from power on to kernel display

Kernel executes in <100ms once loaded.

## Troubleshooting

### Problem: Black screen, nothing happens

**Possible causes**:

1. **ISO not attached**
   - Edit VM settings → CD/DVD
   - Verify ISO path is correct
   - Ensure "Connect at power on" is checked

2. **Wrong boot order**
   - VM may be trying to boot from (non-existent) hard disk
   - Enter BIOS/UEFI setup (F2 on boot)
   - Set CD-ROM as first boot device

3. **Corrupted ISO**
   - Rebuild: `make clean && make`
   - Verify ISO exists: `ls -lh build/nimos.iso`
   - Should be ~5-10 MB

### Problem: "No bootable device found"

**Solution**:

- ISO is not properly attached or not bootable
- Check VM settings → CD/DVD → Connected checkbox
- Ensure ISO path is correct
- Try rebuilding ISO: `make iso`

### Problem: VM boots but shows UEFI/BIOS setup

**Solution**:

- Boot order is wrong
- In setup, go to Boot tab
- Move CD-ROM to top
- Save and exit (F10)

### Problem: Limine menu appears but kernel doesn't load

**Solution**:

- Kernel ELF may be corrupted
- Rebuild kernel: `make clean && make target-a`
- Check kernel exists in ISO:
  ```bash
  xorriso -indev build/nimos.iso -find /
  # Should show: /kernel.elf
  ```

### Problem: Kernel loads but crashes/reboots

**Possible causes**:

1. **Nim compilation issue**
   - Ensure all flags are correct (see BUILD.md)
   - Try updating Nim: `choosenim update stable`

2. **Memory issue**
   - Increase VM RAM to 1 GB
   - Edit VM settings → Memory → 1024 MB

3. **Framebuffer issue**
   - Try different firmware (UEFI ↔ BIOS)
   - Check VM display settings (16 MB video RAM minimum)

### Problem: Can't enter BIOS/UEFI setup

**Solution**:

- VM boots too fast
- Edit VM settings → Options → Boot Delay
- Set delay to 3000 ms (3 seconds)
- This gives you time to press F2

### Problem: Display is corrupted/garbled

**Solution**:

1. **Wrong pixel format assumption**
   - Limine should provide 32-bit ARGB
   - If not, try different VMware version

2. **Resolution issue**
   - Target B requires ≥800×600 framebuffer
   - VMware should provide this by default
   - Try increasing video memory

## Advanced Configuration

### Enable Serial Console (for debugging)

1. Edit VM settings → Add → Serial Port
2. Use named pipe:
   - **Windows**: `\\.\pipe\nimos`
   - **Linux**: `/tmp/nimos`
3. Select: **"This end is the server"**
4. Check: **"The other end is an application"**

Connect with:
```bash
# Linux
socat - UNIX-CONNECT:/tmp/nimos

# Windows (use PuTTY or similar)
# Configure PuTTY to connect to named pipe \\.\pipe\nimos
```

Note: Kernel doesn't output to serial by default. You'd need to add serial driver code.

### Snapshot VM State

After first successful boot:

1. VM → Snapshot → Take Snapshot
2. Name: "Clean boot"
3. Description: "First successful kernel boot"

This lets you quickly restore to working state if you break something.

### Clone VM

To test both Target A and B without rebuilding:

1. Right-click VM → Manage → Clone
2. Create full clone
3. Name: "nimos-target-b"
4. Attach different ISO to each VM

## Performance Notes

### Expected Metrics

- **Boot time**: 1-3 seconds (UEFI faster than BIOS)
- **Kernel load time**: <100 ms
- **Framebuffer initialization**: <10 ms
- **Text rendering**: <1 ms (Target A)
- **Image blit**: ~20-50 ms (Target B, 1.8 MB transfer)

### CPU Usage

After boot, CPU should be near 0%:
- Kernel halts with `HLT` instruction
- VMware efficiently handles halted state
- No busy-wait loops

### Memory Usage

Kernel memory footprint:
- **Target A**: ~200-300 KB
- **Target B**: ~2.1-2.2 MB (includes embedded logo)

VMware will allocate 512 MB - 1 GB to VM, but kernel only uses tiny fraction.

## Screenshots

To take screenshots of your kernel:

1. **VMware method**:
   - VM → Capture Screen
   - Saves to clipboard or file

2. **Manual method**:
   - Press **PrintScreen** while VM is in focus
   - Paste into image editor

## Multi-Monitor Setup

If using multiple monitors:

1. Edit VM settings → Display
2. Number of monitors: 1 (kernel doesn't support multi-monitor)
3. If you want VM on different monitor:
   - Drag VM window to that monitor
   - Enter full screen mode (Ctrl+Alt+Enter)

## Updating Kernel

To test new kernel builds:

1. **Shutdown VM** (VM → Power → Shut Down Guest)
   - Don't just close window!
   - Kernel is halted, so "shutdown" is instant

2. **Rebuild kernel**:
   ```bash
   make clean
   make target-a  # or target-b
   ```

3. **Power on VM**
   - No need to detach/reattach ISO
   - VMware reads latest ISO file contents

4. **Repeat** as needed

**Tip**: Keep VM window and build terminal side-by-side for rapid iteration.

## Creating Multiple Test VMs

Efficient workflow for testing:

1. Create base VM (as described above)
2. Take snapshot: "Base config"
3. Clone VM for each test scenario:
   - Clone 1: Target A testing
   - Clone 2: Target B testing
   - Clone 3: Experimental features

Clones share base disk (linked clones), saving space.

## VM Settings Summary

Recommended final configuration:

| Setting | Value |
|---------|-------|
| Guest OS | Other 64-bit |
| Firmware | UEFI (or BIOS) |
| Processors | 1 |
| Cores | 1 |
| Memory | 1024 MB |
| Hard Disk | None (removed) |
| CD/DVD | nimos.iso (connected) |
| Network | None |
| Display | 16 MB video RAM |
| 3D Graphics | Disabled |

## Known Issues

### Issue: Limine timeout not working

**Symptom**: Limine waits 5 seconds even with `TIMEOUT=0`

**Workaround**: Limine may have minimum timeout. Not a problem, just wait.

### Issue: VM suspends/resumes show corrupted screen

**Symptom**: Resuming from suspend shows garbage

**Workaround**: Kernel doesn't handle suspend/resume. Reset VM instead of resuming.

### Issue: Full screen mode has wrong aspect ratio

**Solution**: VMware may stretch display.
- Edit VM settings → Display → "Maintain aspect ratio"
- Or use windowed mode

## Alternative: QEMU

If you prefer QEMU over VMware:

```bash
qemu-system-x86_64 \
  -cdrom build/nimos.iso \
  -m 512M \
  -boot d \
  -vga std

# Or with UEFI:
qemu-system-x86_64 \
  -cdrom build/nimos.iso \
  -m 512M \
  -boot d \
  -bios /usr/share/ovmf/OVMF.fd \
  -vga std
```

Note: QEMU has different quirks. VMware is recommended per original requirements.

## Next Steps

After successful boot:

1. **Experiment**: Modify kernel.nim, rebuild, reboot
2. **Add features**: Keyboard input, more graphics, etc.
3. **Learn**: Read OSDev wiki (https://wiki.osdev.org)
4. **Share**: Take screenshots and share your OS!

## Support

If you encounter issues not covered here:

1. Check README.md "Troubleshooting" section
2. Verify build completed successfully (BUILD.md)
3. Try different firmware (UEFI ↔ BIOS)
4. Clean rebuild: `make distclean && make`
5. Check VMware version (latest is best)
