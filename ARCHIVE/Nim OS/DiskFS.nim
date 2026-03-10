import VFS

const
  DiskFSBlockSize*  = 4096'u32
  DiskFSMagic*      = 0x4E494D46'u32   # "NIMF"
  DiskFSMaxEntries* = 64

type
  FSSuperblock* = object
    Magic*: uint32
    TotalBlocks*: uint32
    RootDirBlock*: uint32

  FSDirEntryType* = enum
    FSDirEntryUnused = 0'u8
    FSDirEntryFile   = 1'u8
    FSDirEntryDir    = 2'u8

  FSDirEntry* = object
    EntryType*: uint8          # FSDirEntryType
    NameLen*: uint8
    Reserved*: array[2, uint8]
    Size*: uint32              # bytes
    FirstBlock*: uint32        # first data block
    Name*: array[56, char]     # fixed-size name

  DiskFSInode* = object
    DirEntryBlock*: uint32     # block index containing the dir entry
    DirEntryIndex*: uint32     # index within that block (for now always 0 for root files)

  DiskFSListResult* = object
    entries*: array[DiskFSMaxEntries, FSObject]
    count*: int

var
  DiskFSSuper*:      FSSuperblock
  DiskFSRootEntries*: array[DiskFSMaxEntries, FSDirEntry]
  DiskFSRootCount*:  int

proc malloc(size: uint): pointer {.importc.}

# TODO: replace with real disk I/O later
proc DiskReadBlock*(blk: uint32, buf: pointer) =
  ## Stub that will be replaced once we have a real block device.
  ## For now, do nothing so it compiles.
  discard

proc DiskFSLoadSuperblock*() =
  var tmp: array[4096, byte]
  DiskReadBlock(0'u32, addr tmp[0])
  # interpret beginning as FSSuperblock
  DiskFSSuper.Magic = cast[ptr uint32](addr tmp[0])[]
  DiskFSSuper.TotalBlocks = cast[ptr uint32](addr tmp[4])[]
  DiskFSSuper.RootDirBlock = cast[ptr uint32](addr tmp[8])[]

proc DiskFSLoadRootDir*() =
  var tmp {.noinit.}: array[4096, byte]
  DiskReadBlock(DiskFSSuper.RootDirBlock, addr tmp[0])

  DiskFSRootCount = 0
  let entrySize = sizeof(FSDirEntry)
  let maxEntries = int(DiskFSBlockSize) div entrySize

  var i = 0
  while i < maxEntries and DiskFSRootCount < DiskFSMaxEntries:
    let base = i * entrySize
    let entryPtr = cast[ptr FSDirEntry](addr tmp[base])
    if FSDirEntryType(entryPtr.EntryType) != FSDirEntryUnused:
      DiskFSRootEntries[DiskFSRootCount] = entryPtr[]
      DiskFSRootCount += 1
    i += 1

proc DiskFSInit*() =
  DiskFSLoadSuperblock()
  DiskFSLoadRootDir()

proc DiskFSListRoot*(): DiskFSListResult =
  result.count = DiskFSRootCount
  var idx = 0
  while idx < DiskFSRootCount:
    let ep = unsafeAddr DiskFSRootEntries[idx]
    result.entries[idx].FSType =
      (if FSDirEntryType(ep.EntryType) == FSDirEntryDir: FS_DIRECTORY else: FS_FILE)
    result.entries[idx].Parent = nil
    result.entries[idx].Size = uint64(ep.Size)
    let nLen = min(int(ep.NameLen), 63)
    var ni = 0
    while ni < nLen:
      result.entries[idx].Name[ni] = ep.Name[ni]
      ni += 1
    result.entries[idx].Name[nLen] = '\0'
    var inode = cast[ptr DiskFSInode](malloc(uint(sizeof(DiskFSInode))))
    if inode != nil:
      inode.DirEntryBlock = DiskFSSuper.RootDirBlock
      inode.DirEntryIndex = 0'u32
    result.entries[idx].Impl = inode
    idx += 1
