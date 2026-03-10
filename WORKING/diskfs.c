/* diskfs.c - Block-device filesystem implementation for nimos */
#include "diskfs.h"

FSSuperblock DiskFSSuper;
FSDirEntry   DiskFSRootEntries[DISKFS_MAX_ENTRIES];
int          DiskFSRootCount;

/* Stub: replace with real block device I/O once hardware is wired */
void DiskReadBlock(uint32_t blk, void *buf) {
    (void)blk;
    (void)buf;
}

void DiskFSLoadSuperblock(void) {
    unsigned char tmp[4096] = {0};
    DiskReadBlock(0, tmp);
    DiskFSSuper.Magic        = *(uint32_t *)(tmp + 0);
    DiskFSSuper.TotalBlocks  = *(uint32_t *)(tmp + 4);
    DiskFSSuper.RootDirBlock = *(uint32_t *)(tmp + 8);
}

void DiskFSLoadRootDir(void) {
    unsigned char tmp[4096];
    DiskReadBlock(DiskFSSuper.RootDirBlock, tmp);

    DiskFSRootCount = 0;
    int entrySize  = (int)sizeof(FSDirEntry);
    int maxEntries = (int)DISKFS_BLOCK_SIZE / entrySize;

    for (int i = 0; i < maxEntries && DiskFSRootCount < DISKFS_MAX_ENTRIES; i++) {
        FSDirEntry *ep = (FSDirEntry *)(tmp + i * entrySize);
        if ((FSDirEntryType)ep->EntryType != FSDirEntryUnused) {
            DiskFSRootEntries[DiskFSRootCount] = *ep;
            DiskFSRootCount++;
        }
    }
}

void DiskFSInit(void) {
    DiskFSLoadSuperblock();
    DiskFSLoadRootDir();
}

DiskFSListResult DiskFSListRoot(void) {
    DiskFSListResult res;
    res.count = DiskFSRootCount;

    for (int idx = 0; idx < DiskFSRootCount; idx++) {
        FSDirEntry *ep = &DiskFSRootEntries[idx];

        res.entries[idx].FSType =
            ((FSDirEntryType)ep->EntryType == FSDirEntryDir) ? FS_DIRECTORY : FS_FILE;
        res.entries[idx].Parent = (void *)0;
        res.entries[idx].Size   = (uint64_t)ep->Size;
        res.entries[idx].Impl   = (void *)0;  /* no malloc in freestanding kernel */

        int nLen = (int)ep->NameLen;
        if (nLen > 63) nLen = 63;
        for (int ni = 0; ni < nLen; ni++)
            res.entries[idx].Name[ni] = ep->Name[ni];
        res.entries[idx].Name[nLen] = '\0';
    }

    return res;
}
