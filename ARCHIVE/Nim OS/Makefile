# Makefile for nimos - Nim OS kernel

# Tools
NIM := nim
CC := gcc
LD := ld
AS := as
OBJCOPY := objcopy
XORRISO := xorriso
PYTHON := python3

# Directories
BUILD_DIR := build
ISO_DIR := $(BUILD_DIR)/iso_root
LIMINE_DIR := limine

# Output files
KERNEL := $(BUILD_DIR)/kernel.elf
ISO := $(BUILD_DIR)/nimos.iso

# Nim compiler flags
NIM_FLAGS := c --os:Standalone --cpu:amd64 --mm:none \
	--threads:off --panics:on --exceptions:goto \
	-d:noSignalHandler -d:useMalloc \
	--passC:"-ffreestanding -nostdlib -mno-red-zone -fno-stack-protector -fno-pic -mcmodel=kernel" \
	--passL:"-nostdlib" \
	--noMain:on --noLinking:on \
	--nimcache:$(BUILD_DIR)/nimcache \
	--out:$(BUILD_DIR)/kernel_nim.o

# Assembly flags
AS_FLAGS := --64

# Linker flags
LD_FLAGS := -T linker.ld -nostdlib

# Targets
.PHONY: all clean target-a target-b iso run-vmware setup-limine convert-logo

all: target-a

# ============================================================================
# Target A: Terminal-like display
# ============================================================================

target-a: $(KERNEL) iso
	@echo "=== Target A built successfully ==="
	@echo "Boot ISO: $(ISO)"

$(KERNEL): kernel.nim start.S linker.ld | $(BUILD_DIR)
	@echo "=== Building nimos kernel (Target A) ==="

	# Ensure kernel.nim has USE_TARGET_A = true
	@grep -q "const USE_TARGET_A = true" kernel.nim || \
		(echo "ERROR: Set USE_TARGET_A = true in kernel.nim" && exit 1)

	# Compile Nim kernel code
	@echo "[1/4] Compiling Nim code..."
	$(NIM) $(NIM_FLAGS) kernel.nim

	# Assemble startup code
	@echo "[2/4] Assembling start.S..."
	$(AS) $(AS_FLAGS) start.S -o $(BUILD_DIR)/start.o

	# Link kernel
	@echo "[3/4] Linking kernel..."
	$(LD) $(LD_FLAGS) -o $(KERNEL) \
		$(BUILD_DIR)/start.o \
		$(BUILD_DIR)/nimcache/@psystem.nim.c.o \
		$(BUILD_DIR)/nimcache/@mVFS.nim.c.o \
		$(BUILD_DIR)/nimcache/@mDiskFS.nim.c.o \
		$(BUILD_DIR)/nimcache/@mkernel.nim.c.o

	# Verify ELF
	@echo "[4/4] Verifying kernel..."
	@file $(KERNEL)
	@echo "=== Kernel built successfully ==="

# ============================================================================
# Target B: Logo display
# ============================================================================

target-b: convert-logo $(KERNEL)-target-b iso
	@echo "=== Target B built successfully ==="
	@echo "Boot ISO: $(ISO)"

convert-logo: logo.png convert_logo.py
	@echo "=== Converting logo.png to logo.bin ==="
	$(PYTHON) convert_logo.py

$(BUILD_DIR)/logo.o: logo.bin | $(BUILD_DIR)
	@echo "=== Embedding logo.bin into object file ==="
	$(OBJCOPY) -I binary -O elf64-x86-64 -B i386:x86-64 \
		--rename-section .data=.logo \
		logo.bin $(BUILD_DIR)/logo.o

$(KERNEL)-target-b: kernel.nim start.S linker.ld $(BUILD_DIR)/logo.o | $(BUILD_DIR)
	@echo "=== Building nimos kernel (Target B) ==="

	# Ensure kernel.nim has USE_TARGET_A = false
	@grep -q "const USE_TARGET_A = false" kernel.nim || \
		(echo "ERROR: Set USE_TARGET_A = false in kernel.nim" && exit 1)

	# Compile Nim kernel code
	@echo "[1/4] Compiling Nim code..."
	$(NIM) $(NIM_FLAGS) kernel.nim

	# Assemble startup code
	@echo "[2/4] Assembling start.S..."
	$(AS) $(AS_FLAGS) start.S -o $(BUILD_DIR)/start.o

	# Link kernel with embedded logo
	@echo "[3/4] Linking kernel with logo..."
	$(LD) $(LD_FLAGS) -o $(KERNEL) \
		$(BUILD_DIR)/start.o \
		$(BUILD_DIR)/kernel_nim.o \
		$(BUILD_DIR)/logo.o

	# Verify ELF
	@echo "[4/4] Verifying kernel..."
	@file $(KERNEL)
	@echo "=== Kernel built successfully ==="

# ============================================================================
# ISO Creation
# ============================================================================

iso: $(KERNEL) limine.conf | setup-limine
	@echo "=== Creating bootable ISO ==="

	# Create ISO directory structure
	@mkdir -p $(ISO_DIR)

	# Copy kernel
	@cp $(KERNEL) $(ISO_DIR)/kernel.elf

	# Copy Limine files
	@cp limine.conf $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-bios.sys $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-bios-cd.bin $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-uefi-cd.bin $(ISO_DIR)/

	# Create EFI boot directory
	@mkdir -p $(ISO_DIR)/EFI/BOOT
	@cp $(LIMINE_DIR)/BOOTX64.EFI $(ISO_DIR)/EFI/BOOT/

	# Create ISO image
	$(XORRISO) -as mkisofs \
		-b limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		$(ISO_DIR) -o $(ISO)

	# Install Limine bootloader to ISO
	@$(LIMINE_DIR)/limine bios-install $(ISO)

	@echo "=== ISO created: $(ISO) ==="

# ============================================================================
# Limine Setup
# ============================================================================

setup-limine:
	@if [ ! -d "$(LIMINE_DIR)" ]; then \
		echo "=== Setting up Limine bootloader ==="; \
		git clone https://github.com/limine-bootloader/limine.git --branch=v8.x-binary --depth=1; \
		$(MAKE) -C $(LIMINE_DIR); \
		echo "=== Limine setup complete ==="; \
	fi

# ============================================================================
# Utility Targets
# ============================================================================

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/nimcache

clean:
	@echo "=== Cleaning build artifacts ==="
	@rm -rf $(BUILD_DIR)
	@rm -f logo.bin
	@echo "=== Clean complete ==="

distclean: clean
	@echo "=== Removing Limine ==="
	@rm -rf $(LIMINE_DIR)

# ============================================================================
# VMware Instructions
# ============================================================================

run-vmware:
	@echo "=== VMware Run Instructions ==="
	@echo ""
	@echo "1. Create a new VM in VMware:"
	@echo "   - Guest OS: Other / Other 64-bit"
	@echo "   - Firmware: UEFI (or BIOS, both work)"
	@echo "   - Memory: 512 MB minimum"
	@echo "   - Remove hard disk (not needed)"
	@echo ""
	@echo "2. Attach ISO to VM's CD/DVD:"
	@echo "   - Edit VM settings -> CD/DVD"
	@echo "   - Use ISO image: $(realpath $(ISO))"
	@echo "   - Connect at power on: YES"
	@echo ""
	@echo "3. Boot order:"
	@echo "   - Ensure CD/DVD is first boot device"
	@echo ""
	@echo "4. Power on the VM"
	@echo ""
	@echo "Expected behavior:"
	@echo "  Target A: Dark blue screen with 'nimos. (VMware test)' and 'ready>' prompt"
	@echo "  Target B: Your logo image displayed at top-left"
	@echo ""
