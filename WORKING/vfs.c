/* vfs.c - Virtual File System implementation for nimos */
#include "vfs.h"

VfsMount vfsMounts[VFS_MAX_MOUNTS];
int      vfsMountCount = 0;

/* ---------- Internal helpers ---------- */

static int startsWithBare(const char *s, const char *prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (s[i] != prefix[i]) return 0;
        i++;
    }
    return 1;
}

static VfsMount *vfsLookupMount(const char *path) {
    VfsMount *best    = (void *)0;
    int       bestLen = -1;
    for (int i = 0; i < vfsMountCount; i++) {
        int plen = 0;
        const char *p = vfsMounts[i].prefix;
        while (p[plen]) plen++;
        if (startsWithBare(path, vfsMounts[i].prefix) && plen > bestLen) {
            best    = &vfsMounts[i];
            bestLen = plen;
        }
    }
    return best;
}

/* ---------- FSFileHandle API ---------- */

FSFileHandle FSFileOpen(FSObject *Obj) {
    FSFileHandle H = {(void *)0, 0};
    if (Obj == (void *)0 || Obj->FSType != FS_FILE) return H;
    H.Object   = Obj;
    H.Position = 0;
    return H;
}

void FSFileClose(FSFileHandle *H) {
    H->Object   = (void *)0;
    H->Position = 0;
}

uint64_t FSFileRead(FSFileHandle *H, void *Buffer, uint64_t Length) {
    (void)Buffer; (void)Length;
    if (H->Object == (void *)0 || H->Object->FSType != FS_FILE) return 0;
    /* TODO: call filesystem-specific read via H->Object->Impl */
    return 0;
}

uint64_t FSFileWrite(FSFileHandle *H, void *Buffer, uint64_t Length) {
    (void)Buffer; (void)Length;
    if (H->Object == (void *)0 || H->Object->FSType != FS_FILE) return 0;
    /* TODO: call filesystem-specific write via H->Object->Impl */
    return 0;
}

void FSFileSeek(FSFileHandle *H, uint64_t NewPos) {
    if (H->Object == (void *)0 || H->Object->FSType != FS_FILE) return;
    H->Position = NewPos;
}

/* ---------- FSDirectoryHandle API ---------- */

FSDirectoryHandle FSDirectoryOpen(FSObject *Obj) {
    FSDirectoryHandle H = {(void *)0, 0};
    if (Obj == (void *)0 || Obj->FSType != FS_DIRECTORY) return H;
    H.Object = Obj;
    H.Index  = 0;
    return H;
}

void FSDirectoryClose(FSDirectoryHandle *H) {
    H->Object = (void *)0;
    H->Index  = 0;
}

FSObject *FSDirectoryNext(FSDirectoryHandle *H) {
    if (H->Object == (void *)0 || H->Object->FSType != FS_DIRECTORY) return (void *)0;
    /* TODO: use H->Object->Impl and H->Index to fetch next FSObject */
    return (void *)0;
}

/* ---------- Path-based stubs ---------- */

FSObject *FSLookupPath(const char *Path) {
    (void)Path;
    /* TODO: implement path traversal from a root FSObject */
    return (void *)0;
}

FSFileHandle FSOpenPath(const char *Path) {
    FSObject *Obj = FSLookupPath(Path);
    return FSFileOpen(Obj);
}

/* ---------- VFS public API ---------- */

int vfsOpen(const char *path, uint32_t flags, uint32_t mode) {
    VfsMount *m = vfsLookupMount(path);
    if (m == (void *)0 || m->fsOps.open == (void *)0) return -1;
    return m->fsOps.open(path, flags, mode);
}

VfsResult vfsClose(int fd) {
    VfsResult lastErr = vfsErrNotFound;
    for (int i = 0; i < vfsMountCount; i++) {
        if (vfsMounts[i].fileOps.close != (void *)0) {
            VfsResult r = vfsMounts[i].fileOps.close(fd);
            if (r == vfsOk)          return vfsOk;
            if (r != vfsErrNotFound) lastErr = r;
        }
    }
    return lastErr;
}

int vfsRead(int fd, void *buf, unsigned int count) {
    for (int i = 0; i < vfsMountCount; i++) {
        if (vfsMounts[i].fileOps.read != (void *)0) {
            int n = vfsMounts[i].fileOps.read(fd, buf, count);
            if (n >= 0) return n;
        }
    }
    return -1;
}

int vfsWrite(int fd, void *buf, unsigned int count) {
    for (int i = 0; i < vfsMountCount; i++) {
        if (vfsMounts[i].fileOps.write != (void *)0) {
            int n = vfsMounts[i].fileOps.write(fd, buf, count);
            if (n >= 0) return n;
        }
    }
    return -1;
}

int64_t vfsSeek(int fd, int64_t offset, VfsWhence whence) {
    for (int i = 0; i < vfsMountCount; i++) {
        if (vfsMounts[i].fileOps.seek != (void *)0) {
            int64_t pos = vfsMounts[i].fileOps.seek(fd, offset, whence);
            if (pos >= 0) return pos;
        }
    }
    return -1;
}

VfsResult vfsUnlink(const char *path) {
    VfsMount *m = vfsLookupMount(path);
    if (m == (void *)0)               return vfsErrNotFound;
    if (m->fsOps.unlink == (void *)0) return vfsErrInval;
    return m->fsOps.unlink(path);
}

VfsResult vfsMkdir(const char *path, uint32_t mode) {
    VfsMount *m = vfsLookupMount(path);
    if (m == (void *)0)              return vfsErrNotFound;
    if (m->fsOps.mkdir == (void *)0) return vfsErrInval;
    return m->fsOps.mkdir(path, mode);
}

VfsResult vfsRmdir(const char *path) {
    VfsMount *m = vfsLookupMount(path);
    if (m == (void *)0)              return vfsErrNotFound;
    if (m->fsOps.rmdir == (void *)0) return vfsErrInval;
    return m->fsOps.rmdir(path);
}

VfsResult vfsStat(const char *path, VfsStat *st) {
    VfsMount *m = vfsLookupMount(path);
    if (m == (void *)0)             return vfsErrNotFound;
    if (m->fsOps.stat == (void *)0) return vfsErrInval;
    return m->fsOps.stat(path, st);
}
