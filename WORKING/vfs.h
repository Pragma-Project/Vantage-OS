/* vfs.h - Virtual File System types and operations for nimos */
#pragma once
#include <stdint.h>

/* ---------- Basic FS object types ---------- */

typedef enum {
    FS_FILE      = 0,
    FS_DIRECTORY = 1
} FSObjectType;

typedef struct FSObject FSObject;
struct FSObject {
    FSObjectType  FSType;
    char          Name[64];
    FSObject     *Parent;   /* parent in the tree, or NULL for root */
    uint64_t      Size;     /* bytes for files, optional for dirs */
    void         *Impl;     /* filesystem-specific data (inode, etc.) */
};

typedef struct {
    FSObject *Object;   /* must point to an FS_FILE */
    uint64_t  Position; /* current byte offset */
} FSFileHandle;

typedef struct {
    FSObject *Object;   /* must point to an FS_DIRECTORY */
    uint64_t  Index;    /* position when iterating entries */
} FSDirectoryHandle;

/* ---------- VFS enums ---------- */

typedef enum {
    vfsSeekSet = 0,
    vfsSeekCur,
    vfsSeekEnd
} VfsWhence;

typedef enum {
    vfsOk = 0,
    vfsErrNotFound,
    vfsErrIo,
    vfsErrInval,
    vfsErrPerm,
    vfsErrExist,
    vfsErrNotEmpty,
    vfsErrNoSpace,
    vfsErrNotDir,
    vfsErrIsDir,
    vfsErrAgain
} VfsResult;

/* ---------- VFS stat ---------- */

typedef struct {
    uint64_t size;
    uint32_t mode;      /* permission bits + file type */
    uint32_t nLinks;
    uint64_t inodeId;
    uint64_t atime;     /* timestamps in whatever units you like */
    uint64_t mtime;
    uint64_t ctime;
} VfsStat;

/* ---------- File and filesystem operation tables ---------- */

typedef struct {
    int       (*read )(int fd, void *buf, unsigned int count);
    int       (*write)(int fd, void *buf, unsigned int count);
    int64_t   (*seek )(int fd, int64_t offset, VfsWhence whence);
    VfsResult (*close)(int fd);
} VfsFileOps;

typedef struct {
    int       (*open  )(const char *path, uint32_t flags, uint32_t mode);
    VfsResult (*unlink)(const char *path);
    VfsResult (*mkdir )(const char *path, uint32_t mode);
    VfsResult (*rmdir )(const char *path);
    VfsResult (*stat  )(const char *path, VfsStat *st);
} VfsFsOps;

/* ---------- Mount table ---------- */

#define VFS_MAX_MOUNTS  8
#define VFS_PREFIX_LEN  64

typedef struct {
    char       prefix[VFS_PREFIX_LEN]; /* "/", "/boot", "/initrd", etc. */
    VfsFsOps   fsOps;
    VfsFileOps fileOps;
} VfsMount;

extern VfsMount vfsMounts[VFS_MAX_MOUNTS];
extern int      vfsMountCount;

/* ---------- FS handle API ---------- */

FSFileHandle      FSFileOpen       (FSObject *Obj);
void              FSFileClose      (FSFileHandle *H);
uint64_t          FSFileRead       (FSFileHandle *H, void *Buffer, uint64_t Length);
uint64_t          FSFileWrite      (FSFileHandle *H, void *Buffer, uint64_t Length);
void              FSFileSeek       (FSFileHandle *H, uint64_t NewPos);

FSDirectoryHandle FSDirectoryOpen  (FSObject *Obj);
void              FSDirectoryClose (FSDirectoryHandle *H);
FSObject         *FSDirectoryNext  (FSDirectoryHandle *H);

FSObject         *FSLookupPath     (const char *Path);
FSFileHandle      FSOpenPath       (const char *Path);

/* ---------- VFS public API ---------- */

int       vfsOpen  (const char *path, uint32_t flags, uint32_t mode);
VfsResult vfsClose (int fd);
int       vfsRead  (int fd, void *buf, unsigned int count);
int       vfsWrite (int fd, void *buf, unsigned int count);
int64_t   vfsSeek  (int fd, int64_t offset, VfsWhence whence);
VfsResult vfsUnlink(const char *path);
VfsResult vfsMkdir (const char *path, uint32_t mode);
VfsResult vfsRmdir (const char *path);
VfsResult vfsStat  (const char *path, VfsStat *st);
