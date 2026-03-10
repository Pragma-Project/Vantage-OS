# Makefile for nimos - C kernel

# Tools
CC      := gcc
LD      := ld
AS      := as
OBJCOPY := objcopy
XORRISO := xorriso
PYTHON  := python3

# Directories
BUILD_DIR := build
ISO_DIR   := $(BUILD_DIR)/iso_root
LIMINE_DIR := limine

# Output files
KERNEL := $(BUILD_DIR)/kernel.elf
ISO    := $(BUILD_DIR)/nimos.iso

# C compiler flags - freestanding x86_64 higher-half kernel
CFLAGS := -ffreestanding -nostdlib -mno-red-zone -fno-stack-protector \
          -fno-pic -mcmodel=kernel -std=c11 -O2 \
          -Wall -Wno-unused-parameter -Wno-unused-function

# Assembly flags
AS_FLAGS := --64

# Linker flags
LD_FLAGS := -T linker.ld -nostdlib

# Source files
C_SRCS := kernel.c vfs.c diskfs.c
C_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SRCS))
ASM_OBJ := $(BUILD_DIR)/start.o

OBJS := $(ASM_OBJ) $(C_OBJS)

.PHONY: all clean iso run-vmware setup-limine target-a target-b

all: target-a

# ============================================================================
# Target A: Terminal-like display (default)
# ============================================================================

target-a: $(KERNEL) iso
	@echo "=== Target A built successfully ==="
	@echo "Boot ISO: $(ISO)"

# ============================================================================
# Target B: Logo display
# ============================================================================

target-b: convert-logo $(BUILD_DIR)/logo.o
	@$(MAKE) $(KERNEL) EXTRA_OBJS=$(BUILD_DIR)/logo.o
	@$(MAKE) iso
	@echo "=== Target B built successfully ==="
	@echo "Boot ISO: $(ISO)"

convert-logo: logo.png convert_logo.py
	@echo "=== Converting logo.png to logo.bin ==="
	$(PYTHON) convert_logo.py

$(BUILD_DIR)/logo.o: logo.bin | $(BUILD_DIR)
	@echo "=== Embedding logo.bin ==="
	$(OBJCOPY) -I binary -O elf64-x86-64 -B i386:x86-64 \
		--rename-section .data=.logo \
		logo.bin $(BUILD_DIR)/logo.o

# ============================================================================
# Build rules
# ============================================================================

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "[CC] $<"
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/start.o: start.S | $(BUILD_DIR)
	@echo "[AS] start.S"
	$(AS) $(AS_FLAGS) start.S -o $@

$(KERNEL): $(OBJS) $(EXTRA_OBJS) linker.ld | $(BUILD_DIR)
	@echo "[LD] kernel.elf"
	$(LD) $(LD_FLAGS) -o $@ $(OBJS) $(EXTRA_OBJS)
	@file $@
	@echo "=== Kernel built ==="

# ============================================================================
# ISO Creation
# ============================================================================

iso: $(KERNEL) limine.conf | setup-limine
	@echo "=== Creating bootable ISO ==="
	@mkdir -p $(ISO_DIR)
	@cp $(KERNEL) $(ISO_DIR)/kernel.elf
	@cp limine.conf $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-bios.sys    $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-bios-cd.bin $(ISO_DIR)/
	@cp $(LIMINE_DIR)/limine-uefi-cd.bin $(ISO_DIR)/
	@mkdir -p $(ISO_DIR)/EFI/BOOT
	@cp $(LIMINE_DIR)/BOOTX64.EFI $(ISO_DIR)/EFI/BOOT/
	$(XORRISO) -as mkisofs \
		-b limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		$(ISO_DIR) -o $(ISO)
	@$(LIMINE_DIR)/limine bios-install $(ISO)
	@echo "=== ISO created: $(ISO) ==="

# ============================================================================
# Limine Setup
# ============================================================================

setup-limine:
	@if [ ! -d "$(LIMINE_DIR)" ]; then \
		echo "=== Setting up Limine bootloader ==="; \
		git clone https://github.com/limine-bootloader/limine.git \
			--branch=v8.x-binary --depth=1; \
		$(MAKE) -C $(LIMINE_DIR); \
		echo "=== Limine setup complete ==="; \
	fi

# ============================================================================
# Utility
# ============================================================================

clean:
	@echo "=== Cleaning ==="
	@rm -rf $(BUILD_DIR)
	@rm -f logo.bin
	@echo "=== Done ==="

distclean: clean
	@rm -rf $(LIMINE_DIR)

run-vmware:
	@echo "=== VMware Run Instructions ==="
	@echo ""
	@echo "1. Create a new VM: Other / Other 64-bit, UEFI or BIOS, 512 MB RAM"
	@echo "2. Attach ISO: $(realpath $(ISO))"
	@echo "3. Boot order: CD/DVD first"
	@echo "4. Power on"
	@echo ""
	@echo "Expected (Target A): dark blue screen, 'nimos.' title, 'ready>' prompt"
	@echo "Expected (Target B): logo image at top-left"
