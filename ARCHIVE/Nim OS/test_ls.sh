#!/bin/bash
ISO="C:\\Users\\azt12\\OneDrive\\Documents\\Code\\Nim OS\\build\\nimos.iso"
LOGFILE_WIN="C:\\Users\\azt12\\OneDrive\\Documents\\Code\\Nim OS\\serial5.log"
LOGFILE_UNIX="/c/Users/azt12/OneDrive/Documents/Code/Nim OS/serial5.log"
QEMU="/c/Program Files/qemu/qemu-system-x86_64.exe"

rm -f "$LOGFILE_UNIX"

(sleep 9 && echo "sendkey l" && sleep 0.3 && echo "sendkey s" && sleep 0.3 && echo "sendkey ret" && sleep 4 && echo "quit") | \
  "$QEMU" -cdrom "$ISO" -serial "file:$LOGFILE_WIN" -m 512M -display none -no-reboot -monitor stdio 2>/dev/null

echo "--- serial5.log ---"
cat "$LOGFILE_UNIX"
