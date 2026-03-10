#!/usr/bin/env python3
"""
convert_logo.py - Convert PNG logo to raw 32-bit pixel buffer

Usage: python convert_logo.py

Reads: logo.png (same directory as this script)
Writes: logo.bin (1280x800 ARGB format, 4 bytes per pixel)
"""

from PIL import Image
import struct
import os

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_PNG = os.path.join(SCRIPT_DIR, "logo.png")
OUTPUT_BIN = os.path.join(SCRIPT_DIR, "logo.bin")

# Target dimensions (match QEMU/VMware default framebuffer)
TARGET_WIDTH = 1280
TARGET_HEIGHT = 800

def convert_png_to_bin():
    print(f"[DEBUG] Reading PNG: {INPUT_PNG}")

    # Open and convert image
    img = Image.open(INPUT_PNG)

    # Convert to RGBA if not already
    if img.mode != 'RGBA':
        print(f"[DEBUG] Converting from {img.mode} to RGBA")
        img = img.convert('RGBA')

    # Resize to target dimensions
    if img.size != (TARGET_WIDTH, TARGET_HEIGHT):
        print(f"[DEBUG] Resizing from {img.size} to {TARGET_WIDTH}x{TARGET_HEIGHT}")
        img = img.resize((TARGET_WIDTH, TARGET_HEIGHT), Image.Resampling.LANCZOS)

    print(f"[DEBUG] Image size: {img.size}")
    print(f"[DEBUG] Image mode: {img.mode}")

    # Get pixel data
    pixels = img.load()

    # Write binary file (ARGB format, 32-bit per pixel)
    with open(OUTPUT_BIN, 'wb') as f:
        for y in range(TARGET_HEIGHT):
            for x in range(TARGET_WIDTH):
                r, g, b, a = pixels[x, y]

                # Pack as ARGB (0xAARRGGBB)
                argb = (a << 24) | (r << 16) | (g << 8) | b

                # Write as little-endian 32-bit integer
                f.write(struct.pack('<I', argb))

    file_size = os.path.getsize(OUTPUT_BIN)
    expected_size = TARGET_WIDTH * TARGET_HEIGHT * 4

    print(f"[DEBUG] Output file: {OUTPUT_BIN}")
    print(f"[DEBUG] File size: {file_size} bytes")
    print(f"[DEBUG] Expected size: {expected_size} bytes")

    if file_size == expected_size:
        print("[DEBUG] Conversion successful!")
    else:
        print(f"[ERROR] Size mismatch! Got {file_size}, expected {expected_size}")
        return False

    return True

if __name__ == "__main__":
    try:
        if not os.path.exists(INPUT_PNG):
            print(f"[ERROR] Input file not found: {INPUT_PNG}")
            exit(1)

        if convert_png_to_bin():
            print("\nSuccess! logo.bin created.")
            print(f"Format: {TARGET_WIDTH}x{TARGET_HEIGHT} ARGB (4 bytes per pixel)")
        else:
            print("\nConversion failed!")
            exit(1)

    except Exception as e:
        print(f"[ERROR] {e}")
        import traceback
        traceback.print_exc()
        exit(1)
