# VFS.nim
# Core Virtual File System types and operations for nimos.

type
  FSObjectType* = enum
    FS_FILE
    FS_DIRECTORY

  FSObject* = object
    FSType*: FSObjectType
    Name*: array[64, char]
    Parent*: ptr FSObject      ## Parent in the tree, or nil for root.
    Size*: uint64              ## Bytes for files, optional for dirs.
    Impl*: pointer             ## Filesystem-specific data (inode, node, etc.)

  FSFileHandle* = object
    Object*: ptr FSObject      ## Must point to an FS_FILE.
    Position*: uint64          ## Current byte offset.

  FSDirectoryHandle* = object
    Object*: ptr FSObject      ## Must point to an FS_DIRECTORY.
    Index*: uint64             ## Position when iterating entries.

# --------------------
# File operations
# --------------------

proc FSFileOpen*(Obj: ptr FSObject): FSFileHandle =
  ## Open a file FSObject and return a file handle.
  if Obj == nil:
    raise newException(IOError, "FSFileOpen: Obj is nil")

  if Obj.FSType != FS_FILE:
    raise newException(IOError, "FSFileOpen: not a file")

  result.Object = Obj
  result.Position = 0

proc FSFileClose*(H: var FSFileHandle) =
  ## Close a file handle. No refcounting yet, just clear it.
  H.Object = nil
  H.Position = 0

proc FSFileRead*(H: var FSFileHandle; Buffer: ptr byte; Length: uint64): uint64 =
  ## Read up to Length bytes into Buffer, return bytes actually read.
  if H.Object == nil or H.Object.FSType != FS_FILE:
    raise newException(IOError, "FSFileRead: invalid handle")

  # TODO: call filesystem-specific read, using H.Object.Impl and H.Position.
  # It should:
  #   - clamp Length at EOF using H.Object.Size
  #   - read into Buffer
  #   - return bytesRead
  #   - advance H.Position by bytesRead
  #
  # For now this is a stub.
  result = 0

proc FSFileWrite*(H: var FSFileHandle; Buffer: ptr byte; Length: uint64): uint64 =
  ## Write up to Length bytes from Buffer, return bytes actually written.
  if H.Object == nil or H.Object.FSType != FS_FILE:
    raise newException(IOError, "FSFileWrite: invalid handle")

  # TODO: call filesystem-specific write, using H.Object.Impl and H.Position.
  # It should:
  #   - write Length bytes from Buffer
  #   - update H.Object.Size if file grew
  #   - advance H.Position by bytesWritten
  #
  # For now this is a stub.
  result = 0

proc FSFileSeek*(H: var FSFileHandle; NewPos: uint64) =
  ## Set the file position. No bounds checks yet.
  if H.Object == nil or H.Object.FSType != FS_FILE:
    raise newException(IOError, "FSFileSeek: invalid handle")

  H.Position = NewPos

# --------------------
# Directory operations
# --------------------

proc FSDirectoryOpen*(Obj: ptr FSObject): FSDirectoryHandle =
  ## Open a directory FSObject and return a directory handle.
  if Obj == nil:
    raise newException(IOError, "FSDirectoryOpen: Obj is nil")

  if Obj.FSType != FS_DIRECTORY:
    raise newException(IOError, "FSDirectoryOpen: not a directory")

  result.Object = Obj
  result.Index = 0

proc FSDirectoryClose*(H: var FSDirectoryHandle) =
  ## Close a directory handle.
  H.Object = nil
  H.Index = 0

proc FSDirectoryNext*(H: var FSDirectoryHandle): ptr FSObject =
  ## Return the next entry in a directory, or nil at end.
  if H.Object == nil or H.Object.FSType != FS_DIRECTORY:
    raise newException(IOError, "FSDirectoryNext: invalid handle")

  # TODO: use H.Object.Impl and H.Index to fetch the next FSObject.
  # Increment H.Index when returning a real entry.
  #
  # For now this is a stub.
  result = nil

# --------------------
# Path-based helpers (stubs)
# --------------------

proc FSLookupPath*(Path: string): ptr FSObject =
  ## Resolve a path to an FSObject (file or directory).
  ## Later: walk from a global FSRollRoot or current working dir.
  discard Path
  # TODO: implement proper path parsing and directory traversal.
  result = nil

proc FSOpenPath*(Path: string): FSFileHandle =
  ## Convenience: open a file by path.
  let Obj = FSLookupPath(Path)
  result = FSFileOpen(Obj)

proc startsWithBare*(s, prefix: string): bool {.inline.} =
  if prefix.len > s.len: return false
  var i = 0
  while i < prefix.len:
    if s[i] != prefix[i]:
      return false
    inc i
  true

# --- Types ----------------------------------------------------------------

type
  VfsWhence* = enum
    vfsSeekSet, vfsSeekCur, vfsSeekEnd

  VfsResult* = enum
    vfsOk,
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

  VfsStat* = object
    size*: uint64
    mode*: uint32      # permission bits + file type if you want
    nLinks*: uint32
    inodeId*: uint64
    atime*: uint64     # timestamps in whatever units you like
    mtime*: uint64
    ctime*: uint64

  VfsFileOps* = object
    read*:  proc(fd: int, buf: pointer, count: uint): int {.nimcall.}
    write*: proc(fd: int, buf: pointer, count: uint): int {.nimcall.}
    seek*:  proc(fd: int, offset: int64, whence: VfsWhence): int64 {.nimcall.}
    close*: proc(fd: int): VfsResult {.nimcall.}

  VfsFsOps* = object
    open*:   proc(path: cstring, flags: uint32, mode: uint32): int {.nimcall.}
    unlink*: proc(path: cstring): VfsResult {.nimcall.}
    mkdir*:  proc(path: cstring, mode: uint32): VfsResult {.nimcall.}
    rmdir*:  proc(path: cstring): VfsResult {.nimcall.}
    stat*:   proc(path: cstring, st: var VfsStat): VfsResult {.nimcall.}

  VfsMount* = object
    prefix*: string          # "/","/boot","/initrd" etc.
    fsOps*: VfsFsOps
    fileOps*: VfsFileOps

var vfsMounts*: seq[VfsMount] = @[]

# For now we assume a flat fd space where the backend
# understands the integer fd that open() returned.
# If you need per-mount fd tables later, you can wrap it.

# --- Helpers --------------------------------------------------------------

proc vfsLookupMount(path: string): ptr VfsMount =
  ## Find the mount with the longest prefix that matches `path`.
  var best: ptr VfsMount = nil
  var bestLen = -1
  for m in vfsMounts.mitems:
    if startsWithBare(path, m.prefix) and m.prefix.len > bestLen:
      best = addr m
      bestLen = m.prefix.len
  result = best

# --- Public API: open / close already exist -------------------------------
# I'll name these vfsOpen/vfsClose/vfsRead/... to avoid clashing
# with any libc-like names you may add later.

proc vfsOpen*(path: string, flags: uint32, mode: uint32 = 0'u32): int =
  let m = vfsLookupMount(path)
  if m == nil: return -1
  return m.fsOps.open(path.cstring, flags, mode)

proc vfsClose*(fd: int): VfsResult =
  # We don't know which mount owns `fd`, so broadcast to all and
  # treat "not ours" as vfsErrAgain. In practice you'll probably
  # want a fd table that records the mount index.
  var lastErr = vfsErrNotFound
  for m in vfsMounts.mitems:
    if m.fileOps.close != nil:
      let r = m.fileOps.close(fd)
      if r == vfsOk:
        return vfsOk
      elif r != vfsErrNotFound:
        lastErr = r
  result = lastErr

# --- New core ops: read / write / seek -----------------------------------

proc vfsRead*(fd: int, buf: pointer, count: uint): int =
  for m in vfsMounts.mitems:
    if m.fileOps.read != nil:
      let n = m.fileOps.read(fd, buf, count)
      if n >= 0:
        return n
  result = -1

proc vfsWrite*(fd: int, buf: pointer, count: uint): int =
  for m in vfsMounts.mitems:
    if m.fileOps.write != nil:
      let n = m.fileOps.write(fd, buf, count)
      if n >= 0:
        return n
  result = -1

proc vfsSeek*(fd: int, offset: int64, whence: VfsWhence): int64 =
  for m in vfsMounts.mitems:
    if m.fileOps.seek != nil:
      let pos = m.fileOps.seek(fd, offset, whence)
      if pos >= 0:
        return pos
  result = -1'i64

# --- Path-based ops: unlink / mkdir / rmdir / stat -----------------------

proc vfsUnlink*(path: string): VfsResult =
  let m = vfsLookupMount(path)
  if m == nil: return vfsErrNotFound
  if m.fsOps.unlink == nil: return vfsErrInval
  result = m.fsOps.unlink(path.cstring)

proc vfsMkdir*(path: string, mode: uint32 = 0o755'u32): VfsResult =
  let m = vfsLookupMount(path)
  if m == nil: return vfsErrNotFound
  if m.fsOps.mkdir == nil: return vfsErrInval
  result = m.fsOps.mkdir(path.cstring, mode)

proc vfsRmdir*(path: string): VfsResult =
  let m = vfsLookupMount(path)
  if m == nil: return vfsErrNotFound
  if m.fsOps.rmdir == nil: return vfsErrInval
  result = m.fsOps.rmdir(path.cstring)

proc vfsStat*(path: string, st: var VfsStat): VfsResult =
  let m = vfsLookupMount(path)
  if m == nil: return vfsErrNotFound
  if m.fsOps.stat == nil: return vfsErrInval
  result = m.fsOps.stat(path.cstring, st)

# --- FSList: path -> seq[FSObject] routing --------------------------------
# DiskFS imports VFS, so VFS cannot import DiskFS (would be circular).
# The kernel wires the actual implementation after mounting via vfsFSListImpl.

# FSList routing is handled at the kernel level (see cmdLs in kernel.nim).
# DiskFS imports VFS, so VFS cannot import DiskFS without a circular dependency.
