/* diskfs.h - Block-device filesystem types and operations for nimos */
#pragma once
#include <stdint.h>
#include "vfs.h"

#define DISKFS_BLOCK_SIZE   4096u
#define DISKFS_MAGIC        0x4E494D46u   /* "NIMF" */
#define DISKFS_MAX_ENTRIES  64

typedef struct {
    uint32_t Magic;
    uint32_t TotalBlocks;
    uint32_t RootDirBlock;
} FSSuperblock;

typedef enum {
    FSDirEntryUnused = 0,
    FSDirEntryFile   = 1,
    FSDirEntryDir    = 2
} FSDirEntryType;

typedef struct {
    uint8_t  EntryType;         /* FSDirEntryType */
    uint8_t  NameLen;
    uint8_t  Reserved[2];
    uint32_t Size;              /* bytes */
    uint32_t FirstBlock;        /* first data block index */
    char     Name[56];          /* fixed-size name field */
} FSDirEntry;

typedef struct {
    uint32_t DirEntryBlock;     /* block index containing the dir entry */
    uint32_t DirEntryIndex;     /* index within that block */
} DiskFSInode;

typedef struct {
    FSObject entries[DISKFS_MAX_ENTRIES];
    int      count;
} DiskFSListResult;

extern FSSuperblock DiskFSSuper;
extern FSDirEntry   DiskFSRootEntries[DISKFS_MAX_ENTRIES];
extern int          DiskFSRootCount;

void             DiskReadBlock      (uint32_t blk, void *buf);
void             DiskFSLoadSuperblock(void);
void             DiskFSLoadRootDir  (void);
void             DiskFSInit         (void);
DiskFSListResult DiskFSListRoot     (void);
