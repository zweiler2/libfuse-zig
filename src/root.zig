//! Hand-written bindings for libfuse 3.18.3

const std = @import("std");
const builtin = @import("builtin");
const defines = @import("defines");

// ----- System Begin ------

/// Type of device numbers.
pub const dev_t = u64;
/// Type of user identifications.
pub const uid_t = u32;
/// Type of group identifications.
pub const gid_t = u32;
/// Type of file serial numbers (LFS).
pub const ino64_t = u64;
/// Type of file attribute bitmasks.
pub const mode_t = u32;
/// Type of file link counts.
pub const nlink_t = usize;
/// Type of process identifications.
pub const pid_t = i32;
/// Type of file sizes and offsets.
pub const off_t = i64;
/// Type to represent block size.
pub const blksize_t = isize;
/// Type to count number of disk blocks (LFS).
pub const blkcnt64_t = i64;
/// Type to count file system blocks (LFS).
pub const fsblkcnt64_t = u64;

const is_x86_64_arch: bool = builtin.target.cpu.arch == .x86_64;
const is_x86_arch: bool = builtin.target.cpu.arch == .x86;
const is_gnu_abi: bool = builtin.target.abi == .gnu;
const is_musl_abi: bool = builtin.target.abi == .musl;

comptime {
    if (!(is_x86_64_arch or is_x86_arch) or
        !(is_gnu_abi or is_musl_abi))
    {
        @compileError("the FUSE bindings support only x86_64 or x86 with glibc or musl");
    }
}

/// `struct timespec` on x86_64 (glibc and musl).
const TimespecX86_64 = extern struct {
    sec: i64 = 0,
    nsec: i64 = 0,

    comptime {
        std.debug.assert(@sizeOf(TimespecX86_64) == 16);
        std.debug.assert(@alignOf(TimespecX86_64) == 8);
        std.debug.assert(@offsetOf(TimespecX86_64, "sec") == 0);
        std.debug.assert(@offsetOf(TimespecX86_64, "nsec") == 8);
    }
};

/// `struct timespec` on i386 with glibc. glibc only switches `time_t` to 64
/// bits when `_TIME_BITS=64` is requested, which libfuse does not do.
const TimespecX86Gnu = extern struct {
    sec: i32 = 0,
    nsec: i32 = 0,

    comptime {
        std.debug.assert(@sizeOf(TimespecX86Gnu) == 8);
        std.debug.assert(@alignOf(TimespecX86Gnu) == 4);
        std.debug.assert(@offsetOf(TimespecX86Gnu, "sec") == 0);
        std.debug.assert(@offsetOf(TimespecX86Gnu, "nsec") == 4);
    }
};

/// `struct timespec` on i386 with musl. musl always uses a 64-bit `time_t`,
/// but `long` (and therefore `tv_nsec`) remains 32-bit.
const TimespecX86Musl = extern struct {
    sec: i64 = 0,
    nsec: i32 = 0,
    _pad: i32 = 0,

    comptime {
        std.debug.assert(@sizeOf(TimespecX86Musl) == 16);
        std.debug.assert(@alignOf(TimespecX86Musl) == 4);
        std.debug.assert(@offsetOf(TimespecX86Musl, "sec") == 0);
        std.debug.assert(@offsetOf(TimespecX86Musl, "nsec") == 8);
    }
};

/// `struct timespec` in the C library ABI libfuse uses.
pub const Timespec =
    if (is_x86_64_arch)
        TimespecX86_64
    else if (is_gnu_abi)
        TimespecX86Gnu
    else
        TimespecX86Musl;

/// musl's legacy 32-bit `timespec`, embedded in the i386 `struct stat`.
const Timespec32 = extern struct {
    sec: i32 = 0,
    nsec: i32 = 0,

    comptime {
        std.debug.assert(@sizeOf(Timespec32) == 8);
        std.debug.assert(@alignOf(Timespec32) == 4);
        std.debug.assert(@offsetOf(Timespec32, "sec") == 0);
        std.debug.assert(@offsetOf(Timespec32, "nsec") == 4);
    }
};

/// `struct stat` on x86_64. glibc and musl use the same layout here.
const StatX86_64 = extern struct {
    /// Device.
    st_dev: dev_t = 0,
    /// File serial number.
    st_ino: ino64_t = 0,
    /// Link count.
    st_nlink: nlink_t = 0,
    /// File mode.
    st_mode: mode_t = 0,
    /// User ID of the file's owner.
    st_uid: uid_t = 0,
    /// Group ID of the file's group.
    st_gid: gid_t = 0,
    __pad0: i32 = 0,
    /// Device number, if device.
    st_rdev: dev_t = 0,
    /// Size of file, in bytes.
    st_size: off_t = 0,
    /// Optimal block size for I/O.
    st_blksize: blksize_t = 0,
    /// Number 512-byte blocks allocated.
    st_blocks: blkcnt64_t = 0,
    /// Time of last access.
    st_atim: TimespecX86_64 = .{},
    /// Time of last modification.
    st_mtim: TimespecX86_64 = .{},
    /// Time of last status change.
    st_ctim: TimespecX86_64 = .{},
    __reserved: [3]i64 = @splat(0),

    comptime {
        std.debug.assert(@sizeOf(StatX86_64) == 144);
        std.debug.assert(@alignOf(StatX86_64) == 8);
        std.debug.assert(@offsetOf(StatX86_64, "st_dev") == 0);
        std.debug.assert(@offsetOf(StatX86_64, "st_ino") == 8);
        std.debug.assert(@offsetOf(StatX86_64, "st_nlink") == 16);
        std.debug.assert(@offsetOf(StatX86_64, "st_mode") == 24);
        std.debug.assert(@offsetOf(StatX86_64, "st_uid") == 28);
        std.debug.assert(@offsetOf(StatX86_64, "st_gid") == 32);
        std.debug.assert(@offsetOf(StatX86_64, "__pad0") == 36);
        std.debug.assert(@offsetOf(StatX86_64, "st_rdev") == 40);
        std.debug.assert(@offsetOf(StatX86_64, "st_size") == 48);
        std.debug.assert(@offsetOf(StatX86_64, "st_blksize") == 56);
        std.debug.assert(@offsetOf(StatX86_64, "st_blocks") == 64);
        std.debug.assert(@offsetOf(StatX86_64, "st_atim") == 72);
        std.debug.assert(@offsetOf(StatX86_64, "st_mtim") == 88);
        std.debug.assert(@offsetOf(StatX86_64, "st_ctim") == 104);
        std.debug.assert(@offsetOf(StatX86_64, "__reserved") == 120);
    }
};

/// `struct stat` on i386 with glibc, built with `_FILE_OFFSET_BITS=64` as
/// libfuse requires. This is the 96-byte `stat64` layout.
const StatX86Gnu = extern struct {
    /// Device.
    st_dev: dev_t = 0,
    __pad1: u16 = 0,
    /// Truncated 32-bit file serial number.
    __st_ino: u32 = 0,
    /// File mode.
    st_mode: mode_t = 0,
    /// Link count.
    st_nlink: nlink_t = 0,
    /// User ID of the file's owner.
    st_uid: uid_t = 0,
    /// Group ID of the file's group.
    st_gid: gid_t = 0,
    /// Device number, if device.
    st_rdev: dev_t = 0,
    __pad2: u16 = 0,
    /// Size of file, in bytes.
    st_size: off_t = 0,
    /// Optimal block size for I/O.
    st_blksize: blksize_t = 0,
    /// Number 512-byte blocks allocated.
    st_blocks: blkcnt64_t = 0,
    /// Time of last access.
    st_atim: TimespecX86Gnu = .{},
    /// Time of last modification.
    st_mtim: TimespecX86Gnu = .{},
    /// Time of last status change.
    st_ctim: TimespecX86Gnu = .{},
    /// File serial number.
    st_ino: ino64_t = 0,

    comptime {
        std.debug.assert(@sizeOf(StatX86Gnu) == 96);
        std.debug.assert(@alignOf(StatX86Gnu) == 4);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_dev") == 0);
        std.debug.assert(@offsetOf(StatX86Gnu, "__pad1") == 8);
        std.debug.assert(@offsetOf(StatX86Gnu, "__st_ino") == 12);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_mode") == 16);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_nlink") == 20);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_uid") == 24);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_gid") == 28);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_rdev") == 32);
        std.debug.assert(@offsetOf(StatX86Gnu, "__pad2") == 40);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_size") == 44);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_blksize") == 52);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_blocks") == 56);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_atim") == 64);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_mtim") == 72);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_ctim") == 80);
        std.debug.assert(@offsetOf(StatX86Gnu, "st_ino") == 88);
    }
};

/// `struct stat` on i386 with musl. musl keeps the legacy 32-bit `stat` shape
/// and appends the 64-bit `time_t`/`ino_t` fields.
const StatX86Musl = extern struct {
    /// Device.
    st_dev: u64 = 0,
    __st_dev_padding: i32 = 0,
    __st_ino_truncated: i32 = 0,
    /// File mode.
    st_mode: mode_t = 0,
    /// Link count.
    st_nlink: nlink_t = 0,
    /// User ID of the file's owner.
    st_uid: uid_t = 0,
    /// Group ID of the file's group.
    st_gid: uid_t = 0,
    /// Device number, if device.
    st_rdev: dev_t = 0,
    __st_rdev_padding: i32 = 0,
    /// Size of file, in bytes.
    st_size: off_t = 0,
    /// Optimal block size for I/O.
    st_blksize: blksize_t = 0,
    /// Number 512-byte blocks allocated.
    st_blocks: blkcnt64_t = 0,
    __st_atim32: Timespec32 = .{},
    __st_mtim32: Timespec32 = .{},
    __st_ctim32: Timespec32 = .{},
    /// File serial number.
    st_ino: ino64_t = 0,
    /// Time of last access.
    st_atim: TimespecX86Musl = .{},
    /// Time of last modification.
    st_mtim: TimespecX86Musl = .{},
    /// Time of last status change.
    st_ctim: TimespecX86Musl = .{},

    comptime {
        std.debug.assert(@sizeOf(StatX86Musl) == 144);
        std.debug.assert(@alignOf(StatX86Musl) == 4);
        std.debug.assert(@offsetOf(StatX86Musl, "st_dev") == 0);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_dev_padding") == 8);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_ino_truncated") == 12);
        std.debug.assert(@offsetOf(StatX86Musl, "st_mode") == 16);
        std.debug.assert(@offsetOf(StatX86Musl, "st_nlink") == 20);
        std.debug.assert(@offsetOf(StatX86Musl, "st_uid") == 24);
        std.debug.assert(@offsetOf(StatX86Musl, "st_gid") == 28);
        std.debug.assert(@offsetOf(StatX86Musl, "st_rdev") == 32);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_rdev_padding") == 40);
        std.debug.assert(@offsetOf(StatX86Musl, "st_size") == 44);
        std.debug.assert(@offsetOf(StatX86Musl, "st_blksize") == 52);
        std.debug.assert(@offsetOf(StatX86Musl, "st_blocks") == 56);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_atim32") == 64);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_mtim32") == 72);
        std.debug.assert(@offsetOf(StatX86Musl, "__st_ctim32") == 80);
        std.debug.assert(@offsetOf(StatX86Musl, "st_ino") == 88);
        std.debug.assert(@offsetOf(StatX86Musl, "st_atim") == 96);
        std.debug.assert(@offsetOf(StatX86Musl, "st_mtim") == 112);
        std.debug.assert(@offsetOf(StatX86Musl, "st_ctim") == 128);
    }
};

/// `struct stat` in the C library ABI libfuse uses.
pub const Stat =
    if (is_x86_64_arch)
        StatX86_64
    else if (is_gnu_abi)
        StatX86Gnu
    else
        StatX86Musl;

/// `struct statvfs` on 64-bit targets.
const StatVfs64 = extern struct {
    f_bsize: u64 = 0,
    f_frsize: u64 = 0,
    f_blocks: fsblkcnt64_t = 0,
    f_bfree: fsblkcnt64_t = 0,
    f_bavail: fsblkcnt64_t = 0,
    f_files: fsblkcnt64_t = 0,
    f_ffree: fsblkcnt64_t = 0,
    f_favail: fsblkcnt64_t = 0,
    f_fsid: u64 = 0,
    f_flag: u64 = 0,
    f_namemax: u64 = 0,
    f_type: u32 = 0,
    __f_spare: [5]i32 = @splat(0),

    comptime {
        std.debug.assert(@sizeOf(StatVfs64) == 112);
        std.debug.assert(@alignOf(StatVfs64) == 8);
        std.debug.assert(@offsetOf(StatVfs64, "f_bsize") == 0);
        std.debug.assert(@offsetOf(StatVfs64, "f_frsize") == 8);
        std.debug.assert(@offsetOf(StatVfs64, "f_blocks") == 16);
        std.debug.assert(@offsetOf(StatVfs64, "f_bfree") == 24);
        std.debug.assert(@offsetOf(StatVfs64, "f_bavail") == 32);
        std.debug.assert(@offsetOf(StatVfs64, "f_files") == 40);
        std.debug.assert(@offsetOf(StatVfs64, "f_ffree") == 48);
        std.debug.assert(@offsetOf(StatVfs64, "f_favail") == 56);
        std.debug.assert(@offsetOf(StatVfs64, "f_fsid") == 64);
        std.debug.assert(@offsetOf(StatVfs64, "f_flag") == 72);
        std.debug.assert(@offsetOf(StatVfs64, "f_namemax") == 80);
        std.debug.assert(@offsetOf(StatVfs64, "f_type") == 88);
        std.debug.assert(@offsetOf(StatVfs64, "__f_spare") == 92);
    }
};

/// `struct statvfs` on 32-bit targets. glibc with `_FILE_OFFSET_BITS=64` and
/// musl agree on this layout: 32-bit `f_bsize`/`f_frsize`/`f_fsid`/`f_flag`,
/// 64-bit block and inode counts.
const StatVfs32 = extern struct {
    f_bsize: u32 = 0,
    f_frsize: u32 = 0,
    f_blocks: fsblkcnt64_t = 0,
    f_bfree: fsblkcnt64_t = 0,
    f_bavail: fsblkcnt64_t = 0,
    f_files: fsblkcnt64_t = 0,
    f_ffree: fsblkcnt64_t = 0,
    f_favail: fsblkcnt64_t = 0,
    f_fsid: u32 = 0,
    __f_unused: i32 = 0,
    f_flag: u32 = 0,
    f_namemax: u32 = 0,
    f_type: u32 = 0,
    __f_spare: [5]i32 = @splat(0),

    comptime {
        std.debug.assert(@sizeOf(StatVfs32) == 96);
        std.debug.assert(@alignOf(StatVfs32) == 4);
        std.debug.assert(@offsetOf(StatVfs32, "f_bsize") == 0);
        std.debug.assert(@offsetOf(StatVfs32, "f_frsize") == 4);
        std.debug.assert(@offsetOf(StatVfs32, "f_blocks") == 8);
        std.debug.assert(@offsetOf(StatVfs32, "f_bfree") == 16);
        std.debug.assert(@offsetOf(StatVfs32, "f_bavail") == 24);
        std.debug.assert(@offsetOf(StatVfs32, "f_files") == 32);
        std.debug.assert(@offsetOf(StatVfs32, "f_ffree") == 40);
        std.debug.assert(@offsetOf(StatVfs32, "f_favail") == 48);
        std.debug.assert(@offsetOf(StatVfs32, "f_fsid") == 56);
        std.debug.assert(@offsetOf(StatVfs32, "__f_unused") == 60);
        std.debug.assert(@offsetOf(StatVfs32, "f_flag") == 64);
        std.debug.assert(@offsetOf(StatVfs32, "f_namemax") == 68);
        std.debug.assert(@offsetOf(StatVfs32, "f_type") == 72);
        std.debug.assert(@offsetOf(StatVfs32, "__f_spare") == 76);
    }
};

/// `struct statvfs` in the C library ABI libfuse uses.
pub const StatVfs =
    if (is_x86_64_arch)
        StatVfs64
    else
        StatVfs32;

/// `statvfs.f_flag` bit: read-only file system.
pub const ST_RDONLY: c_ulong = 1;

/// `struct flock`.
pub const Flock = std.os.linux.Flock;
/// `struct statx`.
pub const Statx = std.os.linux.Statx;
/// `struct statx_timestamp`.
pub const StatxTimestamp = std.os.linux.statx_timestamp;
/// `stx_mask` bits.
pub const STATX = std.os.linux.STATX;
/// `stx_attributes` bits.
pub const STATX_ATTR = std.os.linux.STATX_ATTR;

// ----- System End ------

// ----- fuse.h Begin ------

pub const FUSE_MAJOR_VERSION = 3;
pub const FUSE_MINOR_VERSION = 18;
pub const FUSE_HOTFIX_VERSION = 3;

/// Handle for a FUSE filesystem
pub const Fuse = opaque {};

/// Readdir flags, passed to ->readdir()
pub const ReaddirFlags = enum(c_uint) {
    /// "Plus" mode.
    ///
    /// The kernel wants to prefill the inode cache during readdir.  The
    /// filesystem may honour this by filling in the attributes and setting
    /// FUSE_FILL_DIR_FLAGS for the filler function.  The filesystem may also
    /// just ignore this flag completely.
    FUSE_READDIR_DEFAULTS = 0,
    FUSE_READDIR_PLUS = (1 << 0),
};

/// Readdir flags, passed to fuse_fill_dir_t callback.
pub const FillDirFlags = enum(c_uint) {
    /// "Plus" mode: file attributes are valid
    ///
    /// The attributes are used by the kernel to prefill the inode cache
    /// during a readdir.
    ///
    /// It is okay to set FUSE_FILL_DIR_PLUS if FUSE_READDIR_PLUS is not set
    /// and vice versa.
    ///
    /// This does not make libfuse honor the 'st_ino' field. That is
    /// controlled by the 'use_ino' option instead.
    FUSE_FILL_DIR_DEFAULTS = 0,
    FUSE_FILL_DIR_PLUS = (1 << 1),
};

/// Function to add an entry in a readdir() operation
///
/// The *off* parameter can be any non-zero value that enables the
/// filesystem to identify the current point in the directory
/// stream. It does not need to be the actual physical position. A
/// value of zero is reserved to indicate that seeking in directories
/// is not supported.
///
/// @return 1 if buffer is full, zero otherwise
pub const FillDir = *const fn (
    /// The buffer passed to the readdir() operation
    buf: ?*anyopaque,
    /// The file name of the directory entry
    name: [*c]const u8,
    /// File attributes, can be NULL
    stbuf: ?*const Stat,
    /// Offset of the next entry or zero
    off: off_t,
    /// Fill flags
    flags: FillDirFlags,
) callconv(.c) c_int;

/// Configuration of the high-level API
///
/// This structure is initialized from the arguments passed to
/// fuse_new(), and then passed to the file system's init() handler
/// which should ensure that the configuration is compatible with the
/// file system implementation.
///
/// Note: this data structure is ABI sensitive, new options have to be
/// appended at the end of the structure
pub const Config = extern struct {
    /// If `set_gid` is non-zero, the st_gid attribute of each file
    /// is overwritten with the value of `gid`.
    set_gid: i32,
    gid: u32,
    /// If `set_uid` is non-zero, the st_uid attribute of each file
    /// is overwritten with the value of `uid`.
    set_uid: i32,
    uid: u32,
    /// If `set_mode` is non-zero, the any permissions bits set in
    /// `umask` are unset in the st_mode attribute of each file.
    set_mode: i32,
    umask: u32,
    /// The timeout in seconds for which name lookups will be
    /// cached.
    entry_timeout: f64,
    /// The timeout in seconds for which a negative lookup will be
    /// cached. This means, that if file did not exist (lookup
    /// returned ENOENT), the lookup will only be redone after the
    /// timeout, and the file/directory will be assumed to not
    /// exist until then. A value of zero means that negative
    /// lookups are not cached.
    negative_timeout: f64,
    /// The timeout in seconds for which file/directory attributes
    /// (as returned by e.g. the `getattr` handler) are cached.
    attr_timeout: f64,
    /// Allow requests to be interrupted
    intr: i32,
    /// Specify which signal number to send to the filesystem when
    /// a request is interrupted.  The default is hardcoded to
    /// USR1.
    intr_signal: i32,
    /// Normally, FUSE assigns inodes to paths only for as long as
    /// the kernel is aware of them. With this option inodes are
    /// instead remembered for at least this many seconds.  This
    /// will require more memory, but may be necessary when using
    /// applications that make use of inode numbers.
    ///
    /// A number of -1 means that inodes will be remembered for the
    /// entire life-time of the file-system process.
    remember: i32,
    /// The default behavior is that if an open file is deleted,
    /// the file is renamed to a hidden file (.fuse_hiddenXXX), and
    /// only removed when the file is finally released.  This
    /// relieves the filesystem implementation of having to deal
    /// with this problem. This option disables the hiding
    /// behavior, and files are removed immediately in an unlink
    /// operation (or in a rename operation which overwrites an
    /// existing file).
    ///
    /// It is recommended that you not use the hard_remove
    /// option. When hard_remove is set, the following libc
    /// functions fail on unlinked files (returning errno of
    /// ENOENT): read(2), write(2), fsync(2), close(2), f*xattr(2),
    /// ftruncate(2), fstat(2), fchmod(2), fchown(2)
    hard_remove: i32,
    /// Honor the st_ino field in the functions getattr() and
    /// fill_dir(). This value is used to fill in the st_ino field
    /// in the stat(2), lstat(2), fstat(2) functions and the d_ino
    /// field in the readdir(2) function. The filesystem does not
    /// have to guarantee uniqueness, however some applications
    /// rely on this value being unique for the whole filesystem.
    ///
    /// Note that this does *not* affect the inode that libfuse
    /// and the kernel use internally (also called the "nodeid").
    use_ino: i32,
    /// If use_ino option is not given, still try to fill in the
    /// d_ino field in readdir(2). If the name was previously
    /// looked up, and is still in the cache, the inode number
    /// found there will be used.  Otherwise it will be set to -1.
    /// If use_ino option is given, this option is ignored.
    readdir_ino: i32,
    /// This option disables the use of page cache (file content cache)
    /// in the kernel for this filesystem. This has several affects:
    ///
    /// 1. Each read(2) or write(2) system call will initiate one
    ///    or more read or write operations, data will not be
    ///    cached in the kernel.
    ///
    /// 2. The return value of the read() and write() system calls
    ///    will correspond to the return values of the read and
    ///    write operations. This is useful for example if the
    ///    file size is not known in advance (before reading it).
    ///
    /// Internally, enabling this option causes fuse to set the
    /// `direct_io` field of `struct fuse_file_info` - overwriting
    /// any value that was put there by the file system.
    direct_io: i32,
    /// This option disables flushing the cache of the file
    /// contents on every open(2).  This should only be enabled on
    /// filesystems where the file data is never changed
    /// externally (not through the mounted FUSE filesystem).  Thus
    /// it is not suitable for network filesystems and other
    /// intermediate filesystems.
    ///
    /// NOTE: if this option is not specified (and neither
    /// direct_io) data is still cached after the open(2), so a
    /// read(2) system call will not always initiate a read
    /// operation.
    ///
    /// Internally, enabling this option causes fuse to set the
    /// `keep_cache` field of `struct fuse_file_info` - overwriting
    /// any value that was put there by the file system.
    kernel_cache: i32,
    /// This option is an alternative to `kernel_cache`. Instead of
    /// unconditionally keeping cached data, the cached data is
    /// invalidated on open(2) if if the modification time or the
    /// size of the file has changed since it was last opened.
    auto_cache: i32,
    /// The timeout in seconds for which file attributes are cached
    /// for the purpose of checking if auto_cache should flush the
    /// file data on open.
    ac_attr_timeout_set: i32,
    ac_attr_timeout: f64,
    /// If this option is given the file-system handlers for the
    /// following operations will not receive path information:
    /// read, write, flush, release, fallocate, fsync, readdir,
    /// releasedir, fsyncdir, lock, ioctl and poll.
    ///
    /// For the truncate, getattr, chmod, chown and utimens
    /// operations the path will be provided only if the struct
    /// fuse_file_info argument is NULL.
    nullpath_ok: i32,
    /// These 3 options are used by libfuse internally and
    /// should not be touched.
    show_help: i32,
    modules: [*c]u8,
    debug: i32,
    /// `fmask` and `dmask` function the same way as `umask`, but apply
    /// to files and directories separately. If non-zero, `fmask` and
    /// `dmask` take precedence over the `umask` setting.
    fmask: u32,
    dmask: u32,
    /// By default, fuse waits for all pending writes to complete
    /// and calls the FLUSH operation on close(2) of every fuse fd.
    /// With this option, wait and FLUSH are not done for read-only
    /// fuse fd, similar to the behavior of NFS/SMB clients.
    no_rofd_flush: i32,
    ///  Allow parallel direct-io writes to operate on the same file.
    ///
    ///  FUSE implementations which do not handle parallel writes on
    ///  same file/region should NOT enable this option at all as it
    ///  might lead to data inconsistencies.
    ///
    ///  For the FUSE implementations which have their own mechanism
    ///  of cache/data integrity are beneficiaries of this setting as
    ///  it now open doors to parallel writes on the same file (without
    ///  enabling this setting, all direct writes on the same file are
    ///  serialized, resulting in huge data bandwidth loss).
    parallel_direct_writes: i32,
    /// Reserved for future use.
    flags: u32,
    /// Reserved for future use.
    reserved: [48]u64,

    comptime {
        std.debug.assert(@sizeOf(Config) == if (is_x86_64_arch) 520 else 516);
        std.debug.assert(@alignOf(Config) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Config, "set_gid") == 0);
        std.debug.assert(@offsetOf(Config, "gid") == 4);
        std.debug.assert(@offsetOf(Config, "set_uid") == 8);
        std.debug.assert(@offsetOf(Config, "uid") == 12);
        std.debug.assert(@offsetOf(Config, "set_mode") == 16);
        std.debug.assert(@offsetOf(Config, "umask") == 20);
        std.debug.assert(@offsetOf(Config, "entry_timeout") == 24);
        std.debug.assert(@offsetOf(Config, "negative_timeout") == 32);
        std.debug.assert(@offsetOf(Config, "attr_timeout") == 40);
        std.debug.assert(@offsetOf(Config, "intr") == 48);
        std.debug.assert(@offsetOf(Config, "intr_signal") == 52);
        std.debug.assert(@offsetOf(Config, "remember") == 56);
        std.debug.assert(@offsetOf(Config, "hard_remove") == 60);
        std.debug.assert(@offsetOf(Config, "use_ino") == 64);
        std.debug.assert(@offsetOf(Config, "readdir_ino") == 68);
        std.debug.assert(@offsetOf(Config, "direct_io") == 72);
        std.debug.assert(@offsetOf(Config, "kernel_cache") == 76);
        std.debug.assert(@offsetOf(Config, "auto_cache") == 80);
        std.debug.assert(@offsetOf(Config, "ac_attr_timeout_set") == 84);
        std.debug.assert(@offsetOf(Config, "ac_attr_timeout") == 88);
        std.debug.assert(@offsetOf(Config, "nullpath_ok") == 96);
        std.debug.assert(@offsetOf(Config, "show_help") == 100);
        std.debug.assert(@offsetOf(Config, "modules") == 104);
        std.debug.assert(@offsetOf(Config, "debug") == if (is_x86_64_arch) 112 else 108);
        std.debug.assert(@offsetOf(Config, "fmask") == if (is_x86_64_arch) 116 else 112);
        std.debug.assert(@offsetOf(Config, "dmask") == if (is_x86_64_arch) 120 else 116);
        std.debug.assert(@offsetOf(Config, "no_rofd_flush") == if (is_x86_64_arch) 124 else 120);
        std.debug.assert(@offsetOf(Config, "parallel_direct_writes") == if (is_x86_64_arch) 128 else 124);
        std.debug.assert(@offsetOf(Config, "flags") == if (is_x86_64_arch) 132 else 128);
        std.debug.assert(@offsetOf(Config, "reserved") == if (is_x86_64_arch) 136 else 132);
    }
};

/// The file system operations:
///
/// Most of these should work very similarly to the well known UNIX
/// file system operations.  A major exception is that instead of
/// returning an error in 'errno', the operation should return the
/// negated error value (-errno) directly.
///
/// All methods are optional, but some are essential for a useful
/// filesystem (e.g. getattr).  Open, flush, release, fsync, opendir,
/// releasedir, fsyncdir, access, create, truncate, lock, init and
/// destroy are special purpose methods, without which a full featured
/// filesystem can still be implemented.
///
/// In general, all methods are expected to perform any necessary
/// permission checking. However, a filesystem may delegate this task
/// to the kernel by passing the `default_permissions` mount option to
/// `fuse_new()`. In this case, methods will only be called if
/// the kernel's permission check has succeeded.
///
/// Almost all operations take a path which can be of any length.
pub const Operations = extern struct {
    /// Get file attributes.
    ///
    /// Similar to stat().  The 'st_dev' and 'st_blksize' fields are
    /// ignored. The 'st_ino' field is ignored except if the 'use_ino'
    /// mount option is given. In that case it is passed to userspace,
    /// but libfuse and the kernel will still assign a different
    /// inode for internal use (called the "nodeid").
    ///
    /// `fi` will always be NULL if the file is not currently open, but
    /// may also be NULL if the file is open.
    getattr: ?*const fn (
        path: [*c]const u8,
        st: *Stat,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,
    /// Read the target of a symbolic link
    ///
    /// The buffer should be filled with a null terminated string.  The
    /// buffer size argument includes the space for the terminating
    /// null character. If the linkname is too long to fit in the
    /// buffer, it should be truncated. The return value should be 0
    /// for success.
    readlink: ?*const fn (
        path: [*c]const u8,
        buf: [*c]u8,
        size: usize,
    ) callconv(.c) c_int = null,
    /// Create a file node
    ///
    /// This is called for creation of all non-directory, non-symlink
    /// nodes.  If the filesystem defines a create() method, then for
    /// regular files that will be called instead.
    mknod: ?*const fn (
        path: [*c]const u8,
        mode: mode_t,
        dev: dev_t,
    ) callconv(.c) c_int = null,
    /// Create a directory
    ///
    /// Note that the mode argument may not have the type specification
    /// bits set, i.e. S_ISDIR(mode) can be false.  To obtain the
    /// correct directory type bits use  mode|S_IFDIR
    mkdir: ?*const fn (
        path: [*c]const u8,
        mode: mode_t,
    ) callconv(.c) c_int = null,
    /// Remove a file
    unlink: ?*const fn (
        path: [*c]const u8,
    ) callconv(.c) c_int = null,
    /// Remove a directory
    rmdir: ?*const fn (
        path: [*c]const u8,
    ) callconv(.c) c_int = null,
    /// Create a symbolic link
    symlink: ?*const fn (
        target: [*c]const u8,
        linkpath: [*c]const u8,
    ) callconv(.c) c_int = null,
    /// Rename a file
    ///
    /// *flags* may be `RENAME_EXCHANGE` or `RENAME_NOREPLACE`. If
    /// RENAME_NOREPLACE is specified, the filesystem must not
    /// overwrite *newname* if it exists and return an error
    /// instead. If `RENAME_EXCHANGE` is specified, the filesystem
    /// must atomically exchange the two files, i.e. both must
    /// exist and neither may be deleted.
    rename: ?*const fn (
        oldpath: [*c]const u8,
        newpath: [*c]const u8,
        flags: c_uint,
    ) callconv(.c) c_int = null,
    /// Create a hard link to a file
    link: ?*const fn (
        src: [*c]const u8,
        dst: [*c]const u8,
    ) callconv(.c) c_int = null,
    /// Change the permission bits of a file
    ///
    /// `fi` will always be NULL if the file is not currently open, but
    /// may also be NULL if the file is open.
    chmod: ?*const fn (
        path: [*c]const u8,
        mode: mode_t,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,
    /// Change the owner and group of a file
    ///
    /// `fi` will always be NULL if the file is not currently open, but
    /// may also be NULL if the file is open.
    ///
    /// Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    /// expected to reset the setuid and setgid bits.
    chown: ?*const fn (
        path: [*c]const u8,
        uid: uid_t,
        gid: gid_t,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,
    /// Change the size of a file
    ///
    /// `fi` will always be NULL if the file is not currently open, but
    /// may also be NULL if the file is open.
    ///
    /// Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    /// expected to reset the setuid and setgid bits.
    truncate: ?*const fn (
        path: [*c]const u8,
        size: off_t,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,
    /// Open a file
    ///
    /// Open flags are available in fi->flags. The following rules
    /// apply.
    ///
    ///  - Creation (O_CREAT, O_EXCL, O_NOCTTY) flags will be
    ///    filtered out / handled by the kernel.
    ///
    ///  - Access modes (O_RDONLY, O_WRONLY, O_RDWR, O_EXEC, O_SEARCH)
    ///    should be used by the filesystem to check if the operation is
    ///    permitted.  If the ``-o default_permissions`` mount option is
    ///    given, this check is already done by the kernel before calling
    ///    open() and may thus be omitted by the filesystem.
    ///
    ///  - When writeback caching is enabled, the kernel may send
    ///    read requests even for files opened with O_WRONLY. The
    ///    filesystem should be prepared to handle this.
    ///
    ///  - When writeback caching is disabled, the filesystem is
    ///    expected to properly handle the O_APPEND flag and ensure
    ///    that each write is appending to the end of the file.
    ///
    ///  - When writeback caching is enabled, the kernel will
    ///    handle O_APPEND. However, unless all changes to the file
    ///    come through the kernel this will not work reliably. The
    ///    filesystem should thus either ignore the O_APPEND flag
    ///    (and let the kernel handle it), or return an error
    ///    (indicating that reliably O_APPEND is not available).
    ///
    /// Filesystem may store an arbitrary file handle (pointer,
    /// index, etc) in fi->fh, and use this in other all other file
    /// operations (read, write, flush, release, fsync).
    ///
    /// Filesystem may also implement stateless file I/O and not store
    /// anything in fi->fh.
    ///
    /// There are also some flags (direct_io, keep_cache) which the
    /// filesystem may set in fi, to change the way the file is opened.
    /// See fuse_file_info structure in <fuse_common.h> for more details.
    ///
    /// If this request is answered with an error code of ENOSYS
    /// and FUSE_CAP_NO_OPEN_SUPPORT is set in
    /// `fuse_conn_info.capable`, this is treated as success and
    /// future calls to open will also succeed without being sent
    /// to the filesystem process.
    open: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Read data from an open file
    ///
    /// Read should return exactly the number of bytes requested except
    /// on EOF or error, otherwise the rest of the data will be
    /// substituted with zeroes. An exception to this is when the
    /// 'direct_io' mount option is specified, in which case the return
    /// value of the read system call will reflect the return value of
    /// this operation.
    read: ?*const fn (
        path: [*c]const u8,
        buf: [*c]u8,
        size: usize,
        off: off_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Write data to an open file
    ///
    /// Write should return exactly the number of bytes requested
    /// except on error. An exception to this is when the 'direct_io'
    /// mount option is specified (see read operation).
    ///
    /// Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    /// expected to reset the setuid and setgid bits.
    write: ?*const fn (
        path: [*c]const u8,
        buf: [*c]const u8,
        size: usize,
        off: off_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Get file system statistics
    ///
    /// The 'f_favail', 'f_fsid' and 'f_flag' fields are ignored
    statfs: ?*const fn (
        path: [*c]const u8,
        st: *StatVfs,
    ) callconv(.c) c_int = null,
    /// Possibly flush cached data
    ///
    /// BIG NOTE: This is not equivalent to fsync().  It's not a
    /// request to sync dirty data.
    ///
    /// Flush is called on each close() of a file descriptor, as opposed to
    /// release which is called on the close of the last file descriptor for
    /// a file.  Under Linux, errors returned by flush() will be passed to
    /// userspace as errors from close(), so flush() is a good place to write
    /// back any cached dirty data. However, many applications ignore errors
    /// on close(), and on non-Linux systems, close() may succeed even if flush()
    /// returns an error. For these reasons, filesystems should not assume
    /// that errors returned by flush will ever be noticed or even
    /// delivered.
    ///
    /// NOTE: The flush() method may be called more than once for each
    /// open().  This happens if more than one file descriptor refers to an
    /// open file handle, e.g. due to dup(), dup2() or fork() calls.  It is
    /// not possible to determine if a flush is final, so each flush should
    /// be treated equally.  Multiple write-flush sequences are relatively
    /// rare, so this shouldn't be a problem.
    ///
    /// Filesystems shouldn't assume that flush will be called at any
    /// particular point.  It may be called more times than expected, or not
    /// at all.
    ///
    /// [[close]: http://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html](http://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html)
    flush: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Release an open file
    ///
    /// Release is called when there are no more references to an open
    /// file: all file descriptors are closed and all memory mappings
    /// are unmapped.
    ///
    /// For every open() call there will be exactly one release() call
    /// with the same flags and file handle.  It is possible to
    /// have a file opened more than once, in which case only the last
    /// release will mean, that no more reads/writes will happen on the
    /// file.  The return value of release is ignored.
    release: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Synchronize file contents
    ///
    /// If the datasync parameter is non-zero, then only the user data
    /// should be flushed, not the meta data.
    fsync: ?*const fn (
        path: [*c]const u8,
        datasync: c_int,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Set extended attributes
    setxattr: ?*const fn (
        path: [*c]const u8,
        name: [*c]const u8,
        value: [*c]const u8,
        size: usize,
        flags: c_int,
    ) callconv(.c) c_int = null,
    /// Get extended attributes
    getxattr: ?*const fn (
        path: [*c]const u8,
        name: [*c]const u8,
        value: [*c]u8,
        size: usize,
    ) callconv(.c) c_int = null,
    /// List extended attributes
    listxattr: ?*const fn (
        path: [*c]const u8,
        list: [*c]u8,
        size: usize,
    ) callconv(.c) c_int = null,
    /// Remove extended attributes
    removexattr: ?*const fn (
        path: [*c]const u8,
        name: [*c]const u8,
    ) callconv(.c) c_int = null,
    /// Open directory
    ///
    /// Unless the 'default_permissions' mount option is given,
    /// this method should check if opendir is permitted for this
    /// directory. Optionally opendir may also return an arbitrary
    /// filehandle in the fuse_file_info structure, which will be
    /// passed to readdir, releasedir and fsyncdir.
    opendir: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Read directory
    ///
    /// The filesystem may choose between two modes of operation:
    ///
    /// 1) The readdir implementation ignores the offset parameter, and
    /// passes zero to the filler function's offset.  The filler
    /// function will not return '1' (unless an error happens), so the
    /// whole directory is read in a single readdir operation.
    ///
    /// 2) The readdir implementation keeps track of the offsets of the
    /// directory entries.  It uses the offset parameter and always
    /// passes non-zero offset to the filler function.  When the buffer
    /// is full (or an error happens) the filler function will return
    /// '1'.
    ///
    /// When FUSE_READDIR_PLUS is not set, only some parameters of the
    /// fill function (the fuse_fill_dir_t parameter) are actually used:
    /// The file type (which is part of stat::st_mode) is used. And if
    /// fuse_config::use_ino is set, the inode (stat::st_ino) is also
    /// used. The other fields are ignored when FUSE_READDIR_PLUS is not
    /// set.
    readdir: ?*const fn (
        path: [*c]const u8,
        buf: ?*anyopaque,
        filler: FillDir,
        off: off_t,
        fi: *FileInfo,
        flags: ReaddirFlags,
    ) callconv(.c) c_int = null,
    /// Release directory
    ///
    /// If the directory has been removed after the call to opendir, the
    /// path parameter will be NULL.
    releasedir: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Synchronize directory contents
    ///
    /// If the directory has been removed after the call to opendir, the
    /// path parameter will be NULL.
    ///
    /// If the datasync parameter is non-zero, then only the user data
    /// should be flushed, not the meta data
    fsyncdir: ?*const fn (
        path: [*c]const u8,
        datasync: c_int,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Initialize filesystem
    ///
    /// The return value will passed in the `private_data` field of
    /// `struct fuse_context` to all file operations, and as a
    /// parameter to the destroy() method. It overrides the initial
    /// value provided to fuse_main() / fuse_new().
    init: ?*const fn (
        conn: *ConnInfo,
        cfg: *Config,
    ) callconv(.c) ?*anyopaque = null,
    /// Clean up filesystem
    ///
    /// Called on filesystem exit.
    destroy: ?*const fn (
        private_data: ?*anyopaque,
    ) callconv(.c) void = null,
    /// Check file access permissions
    ///
    /// This will be called for the access() system call.  If the
    /// 'default_permissions' mount option is given, this method is not
    /// called.
    ///
    /// This method is not called under Linux kernel versions 2.4.x
    access: ?*const fn (
        path: [*c]const u8,
        mask: c_int,
    ) callconv(.c) c_int = null,
    /// Create and open a file
    ///
    /// If the file does not exist, first create it with the specified
    /// mode, and then open it.
    ///
    /// If this method is not implemented or under Linux kernel
    /// versions earlier than 2.6.15, the mknod() and open() methods
    /// will be called instead.
    create: ?*const fn (
        path: [*c]const u8,
        mode: mode_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Perform POSIX file locking operation
    ///
    /// The cmd argument will be either F_GETLK, F_SETLK or F_SETLKW.
    ///
    /// For the meaning of fields in 'struct flock' see the man page
    /// for fcntl(2).  The l_whence field will always be set to
    /// SEEK_SET.
    ///
    /// For checking lock ownership, the 'fuse_file_info->owner'
    /// argument must be used.
    ///
    /// For F_GETLK operation, the library will first check currently
    /// held locks, and if a conflicting lock is found it will return
    /// information without calling this method. This ensures, that
    /// for local locks the l_pid field is correctly filled in. The
    /// results may not be accurate in case of race conditions and in
    /// the presence of hard links, but it's unlikely that an
    /// application would rely on accurate GETLK results in these
    /// cases.  If a conflicting lock is not found, this method will be
    /// called, and the filesystem may fill out l_pid by a meaningful
    /// value, or it may leave this field zero.
    ///
    /// For F_SETLK and F_SETLKW the l_pid field will be set to the pid
    /// of the process performing the locking operation.
    ///
    /// Note: if this method is not implemented, the kernel will still
    /// allow file locking to work locally.  Hence it is only
    /// interesting for network filesystems and similar.
    lock: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
        cmd: c_int,
        lock: ?*Flock,
    ) callconv(.c) c_int = null,
    /// Change the access and modification times of a file with
    /// nanosecond resolution
    ///
    /// This supersedes the old utime() interface.  New applications
    /// should use this.
    ///
    /// `fi` will always be NULL if the file is not currently open, but
    /// may also be NULL if the file is open.
    ///
    /// See the utimensat(2) man page for details.
    utimens: ?*const fn (
        path: [*c]const u8,
        tv: [*c]const Timespec,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,
    /// Map block index within file to block index within device
    ///
    /// Note: This makes sense only for block device backed filesystems
    /// mounted with the 'blkdev' option
    bmap: ?*const fn (
        path: [*c]const u8,
        blocksize: usize,
        idx: *u64,
    ) callconv(.c) c_int = null,
    /// Ioctl
    ///
    /// flags will have FUSE_IOCTL_COMPAT set for 32bit ioctls in
    /// 64bit environment.  The size and direction of data is
    /// determined by _IOC_*() decoding of cmd.  For _IOC_NONE,
    /// data will be NULL, for _IOC_WRITE data is out area, for
    /// _IOC_READ in area and if both are set in/out area.  In all
    /// non-NULL cases, the area is of _IOC_SIZE(cmd) bytes.
    ///
    /// If flags has FUSE_IOCTL_DIR then the fuse_file_info refers to a
    /// directory file handle.
    ///
    /// Note : the unsigned long request submitted by the application
    /// is truncated to 32 bits.
    ioctl: ?*const fn (
        path: [*c]const u8,
        cmd: c_uint,
        arg: ?*anyopaque,
        fi: *FileInfo,
        flags: IoctlFlags,
        data: ?*anyopaque,
    ) callconv(.c) c_int = null,
    /// Poll for IO readiness events
    ///
    /// Note: If ph is non-NULL, the client should notify
    /// when IO readiness events occur by calling
    /// fuse_notify_poll() with the specified ph.
    ///
    /// Regardless of the number of times poll with a non-NULL ph
    /// is received, single notification is enough to clear all.
    /// Notifying more times incurs overhead but doesn't harm
    /// correctness.
    ///
    /// The callee is responsible for destroying ph with
    /// fuse_pollhandle_destroy() when no longer in use.
    poll: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
        ph: ?*Pollhandle,
        reventsp: *c_uint,
    ) callconv(.c) c_int = null,
    /// Write contents of buffer to an open file
    ///
    /// Similar to the write() method, but data is supplied in a
    /// generic buffer.  Use fuse_buf_copy() to transfer data to
    /// the destination.
    ///
    /// Unless FUSE_CAP_HANDLE_KILLPRIV is disabled, this method is
    /// expected to reset the setuid and setgid bits.
    write_buf: ?*const fn (
        path: [*c]const u8,
        buf: *Bufvec,
        off: off_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Store data from an open file in a buffer
    ///
    /// Similar to the read() method, but data is stored and
    /// returned in a generic buffer.
    ///
    /// No actual copying of data has to take place, the source
    /// file descriptor may simply be stored in the buffer for
    /// later data transfer.
    ///
    /// The buffer must be allocated dynamically and stored at the
    /// location pointed to by bufp.  If the buffer contains memory
    /// regions, they too must be allocated using malloc().  The
    /// allocated memory will be freed by the caller.
    read_buf: ?*const fn (
        path: [*c]const u8,
        bufp: ?*[*c]Bufvec,
        size: usize,
        off: off_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Perform BSD file locking operation
    ///
    /// The op argument will be either LOCK_SH, LOCK_EX or LOCK_UN
    ///
    /// Nonblocking requests will be indicated by ORing LOCK_NB to
    /// the above operations
    ///
    /// For more information see the flock(2) manual page.
    ///
    /// Additionally fi->owner will be set to a value unique to
    /// this open file.  This same value will be supplied to
    /// ->release() when the file is released.
    ///
    /// Note: if this method is not implemented, the kernel will still
    /// allow file locking to work locally.  Hence it is only
    /// interesting for network filesystems and similar.
    flock: ?*const fn (
        path: [*c]const u8,
        fi: *FileInfo,
        op: c_int,
    ) callconv(.c) c_int = null,
    /// Allocates space for an open file
    ///
    /// This function ensures that required space is allocated for specified
    /// file.  If this function returns success then any subsequent write
    /// request to specified range is guaranteed not to fail because of lack
    /// of space on the file system media.
    fallocate: ?*const fn (
        path: [*c]const u8,
        mode: c_int,
        off: off_t,
        length: off_t,
        fi: *FileInfo,
    ) callconv(.c) c_int = null,
    /// Copy a range of data from one file to another
    ///
    /// Performs an optimized copy between two file descriptors without the
    /// additional cost of transferring data through the FUSE kernel module
    /// to user space (glibc) and then back into the FUSE filesystem again.
    ///
    /// In case this method is not implemented, applications are expected to
    /// fall back to a regular file copy.   (Some glibc versions did this
    /// emulation automatically, but the emulation has been removed from all
    /// glibc release branches.)
    copy_file_range: ?*const fn (
        path_in: [*c]const u8,
        fi_in: *FileInfo,
        off_in: off_t,
        path_out: [*c]const u8,
        fi_out: *FileInfo,
        off_out: off_t,
        size: usize,
        flags: c_int,
    ) callconv(.c) isize = null,
    /// Find next data or hole after the specified offset
    lseek: ?*const fn (
        path: [*c]const u8,
        off: off_t,
        whence: c_int,
        fi: *FileInfo,
    ) callconv(.c) off_t = null,
    /// Get extended file attributes.
    ///
    /// fi may be NULL.
    ///
    /// If path is NULL, then the AT_EMPTY_PATH bit in flags will be
    /// already set.
    statx: ?*const fn (
        path: [*c]const u8,
        flags: c_int,
        mask: c_int,
        stxbuf: *Statx,
        fi: ?*FileInfo,
    ) callconv(.c) c_int = null,

    comptime {
        std.debug.assert(@sizeOf(Operations) == 43 * @sizeOf(*anyopaque));
        std.debug.assert(@alignOf(Operations) == @alignOf(usize));
        std.debug.assert(@offsetOf(Operations, "getattr") == 0 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "readlink") == 1 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "mknod") == 2 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "mkdir") == 3 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "unlink") == 4 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "rmdir") == 5 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "symlink") == 6 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "rename") == 7 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "link") == 8 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "chmod") == 9 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "chown") == 10 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "truncate") == 11 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "open") == 12 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "read") == 13 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "write") == 14 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "statfs") == 15 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "flush") == 16 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "release") == 17 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "fsync") == 18 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "setxattr") == 19 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "getxattr") == 20 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "listxattr") == 21 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "removexattr") == 22 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "opendir") == 23 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "readdir") == 24 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "releasedir") == 25 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "fsyncdir") == 26 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "init") == 27 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "destroy") == 28 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "access") == 29 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "create") == 30 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "lock") == 31 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "utimens") == 32 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "bmap") == 33 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "ioctl") == 34 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "poll") == 35 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "write_buf") == 36 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "read_buf") == 37 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "flock") == 38 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "fallocate") == 39 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "copy_file_range") == 40 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "lseek") == 41 * @sizeOf(usize));
        std.debug.assert(@offsetOf(Operations, "statx") == 42 * @sizeOf(usize));
    }
};

/// Extra context that may be needed by some filesystems
///
/// The uid, gid and pid fields are not filled in case of a writepage
/// operation.
pub const Context = extern struct {
    /// Pointer to the fuse object
    fuse: ?*Fuse,
    /// User ID of the calling process
    uid: uid_t,
    /// Group ID of the calling process
    gid: gid_t,
    /// Process ID of the calling thread
    pid: pid_t,
    /// Private filesystem data
    private_data: ?*anyopaque,
    /// Umask of the calling process
    umask: mode_t,

    comptime {
        std.debug.assert(@sizeOf(Context) == if (is_x86_64_arch) 40 else 24);
        std.debug.assert(@alignOf(Context) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Context, "fuse") == 0);
        std.debug.assert(@offsetOf(Context, "uid") == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Context, "gid") == if (is_x86_64_arch) 12 else 8);
        std.debug.assert(@offsetOf(Context, "pid") == if (is_x86_64_arch) 16 else 12);
        std.debug.assert(@offsetOf(Context, "private_data") == if (is_x86_64_arch) 24 else 16);
        std.debug.assert(@offsetOf(Context, "umask") == if (is_x86_64_arch) 32 else 20);
    }
};

/// The real main function
///
/// Do not call this directly, use fuse_main()
pub extern fn fuse_main_real_versioned(
    argc: c_int,
    argv: [*c][*c]u8,
    op: *const Operations,
    op_size: usize,
    version: *LibfuseVersion,
    user_data: ?*anyopaque,
) c_int;
pub inline fn fuse_main_real(
    argc: c_int,
    argv: [*c][*c]u8,
    op: *const Operations,
    op_size: usize,
    user_data: ?*anyopaque,
) c_int {
    var version: LibfuseVersion = .{
        .major = FUSE_MAJOR_VERSION,
        .minor = FUSE_MINOR_VERSION,
        .hotfix = FUSE_HOTFIX_VERSION,
    };

    fuse_log(.ERR, "%s is a libfuse internal function, please use fuse_main()\n", @src().fn_name.ptr);

    return fuse_main_real_versioned(argc, argv, op, op_size, &version, user_data);
}

/// Main function of FUSE.
///
/// This is for the lazy.  This is all that has to be called from the
/// main() function.
///
/// This function does the following:
///   - parses command line options, and handles --help and
///     --version
///   - installs signal handlers for INT, HUP, TERM and PIPE
///   - registers an exit handler to unmount the filesystem on program exit
///   - creates a fuse handle
///   - registers the operations
///   - calls either the single-threaded or the multi-threaded event loop
///
/// Most file systems will have to parse some file-system specific
/// arguments before calling this function. It is recommended to do
/// this with fuse_opt_parse() and a processing function that passes
/// through any unknown options (this can also be achieved by just
/// passing NULL as the processing function). That way, the remaining
/// options can be passed directly to fuse_main().
///
/// fuse_main() accepts all options that can be passed to
/// fuse_parse_cmdline(), fuse_new(), or fuse_session_new().
///
/// Option parsing skips argv[0], which is assumed to contain the
/// program name. This element must always be present and is used to
/// construct a basic ``usage: `` message for the --help
/// output. argv[0] may also be set to the empty string. In this case
/// the usage message is suppressed. This can be used by file systems
/// to print their own usage line first. See hello.c for an example of
/// how to do this.
///
/// Note: this is currently implemented as a macro.
///
/// The following error codes may be returned from fuse_main():
///   1: Invalid option arguments
///   2: No mount point specified
///   3: FUSE setup failed
///   4: Mounting failed
///   5: Failed to daemonize (detach from session)
///   6: Failed to set up signal handlers
///   7: An error occurred during the life of the file system
///
/// @return 0 on success, nonzero on failure
pub inline fn fuse_main_fn(
    /// The argument counter passed to the main() function
    argc: c_int,
    /// The argument vector passed to the main() function
    argv: [*c][*c]u8,
    /// The file system operation
    op: *const Operations,
    /// Initial value for the `private_data`
    /// field of `struct fuse_context`. May be overridden by the
    /// `struct fuse_operations.init` handler.
    user_data: ?*anyopaque,
) c_int {
    var version: LibfuseVersion = .{
        .major = FUSE_MAJOR_VERSION,
        .minor = FUSE_MINOR_VERSION,
        .hotfix = FUSE_HOTFIX_VERSION,
    };
    return fuse_main_real_versioned(argc, argv, op, @sizeOf(Operations), &version, user_data);
}
pub const fuse_main = fuse_main_fn;

// ----- More detailed API Begin -----

/// Print available options (high- and low-level) to stdout.  This is
/// not an exhaustive list, but includes only those options that may be
/// of interest to an end-user of a file system.
///
/// The function looks at the argument vector only to determine if
/// there are additional modules to be loaded (module=foo option),
/// and attempts to call their help functions as well.
pub extern fn fuse_lib_help(
    /// The argument vector.
    args: *Args,
) void;

/// Do not call this directly, use fuse_new() instead
pub extern fn _fuse_new_30(
    args: *Args,
    op: *const Operations,
    op_size: usize,
    version: *LibfuseVersion,
    user_data: ?*anyopaque,
) ?*Fuse;
/// Do not call this directly, use fuse_new() instead
pub extern fn _fuse_new_31(
    args: *Args,
    op: *const Operations,
    op_size: usize,
    version: *LibfuseVersion,
    user_data: ?*anyopaque,
) ?*Fuse;

/// Create a new FUSE filesystem.
///
/// This function accepts most file-system independent mount options
/// (like context, nodev, ro - see mount(8)), as well as the
/// FUSE-specific mount options from mount.fuse(8).
///
/// If the --help option is specified, the function writes a help text
/// to stdout and returns NULL.
///
/// Option parsing skips argv[0], which is assumed to contain the
/// program name. This element must always be present and is used to
/// construct a basic ``usage: `` message for the --help output. If
/// argv[0] is set to the empty string, no usage message is included in
/// the --help output.
///
/// If an unknown option is passed in, an error message is written to
/// stderr and the function returns NULL.
///
/// @return the created FUSE handle
pub inline fn fuse_new_fn(
    /// Argument vector
    args: *Args,
    /// The filesystem operations
    op: *const Operations,
    /// The size of the fuse_operations structure
    op_size: usize,
    /// Initial value for the `private_data`
    /// field of `struct fuse_context`. May be overridden by the
    /// `struct fuse_operations.init` handler.
    user_data: ?*anyopaque,
) ?*Fuse {
    var version: LibfuseVersion = .{
        .major = FUSE_MAJOR_VERSION,
        .minor = FUSE_MINOR_VERSION,
        .hotfix = FUSE_HOTFIX_VERSION,
    };

    return _fuse_new_31(args, op, op_size, &version, user_data);
}
pub const fuse_new = fuse_new_fn;

/// Mount a FUSE file system.
///
/// @return 0 on success, -1 on failure.
pub extern fn fuse_mount(
    /// The FUSE handle
    f: *Fuse,
    /// The mount point path
    mountpoint: [*c]const u8,
) c_int;

/// Unmount a FUSE file system.
///
/// See fuse_session_unmount() for additional information.
pub extern fn fuse_unmount(
    /// The FUSE handle
    f: *Fuse,
) void;

/// Destroy the FUSE handle.
///
/// NOTE: This function does not unmount the filesystem. If this is
/// needed, call fuse_unmount() before calling this function.
pub extern fn fuse_destroy(
    /// The FUSE handle
    f: *Fuse,
) void;

/// FUSE event loop.
///
/// Requests from the kernel are processed, and the appropriate
/// operations are called.
///
/// For a description of the return value and the conditions when the
/// event loop exits, refer to the documentation of
/// fuse_session_loop().
///
/// @return see fuse_session_loop()
///
/// See also: fuse_loop_mt()
pub extern fn fuse_loop(
    /// The FUSE handle
    f: *Fuse,
) c_int;

/// Flag session as terminated
///
/// This function will cause any running event loops to exit on
/// the next opportunity.
pub extern fn fuse_exit(
    /// The FUSE handle
    f: *Fuse,
) void;

/// FUSE event loop with multiple threads
///
/// Requests from the kernel are processed, and the appropriate
/// operations are called.  Request are processed in parallel by
/// distributing them between multiple threads.
///
/// For a description of the return value and the conditions when the
/// event loop exits, refer to the documentation of
/// fuse_session_loop().
///
/// Note: using fuse_loop() instead of fuse_loop_mt() means you are running in
/// single-threaded mode, and that you will not have to worry about reentrancy,
/// though you will have to worry about recursive lookups. In single-threaded
/// mode, FUSE will wait for one callback to return before calling another.
///
/// Enabling multiple threads, by using fuse_loop_mt(), will cause FUSE to make
/// multiple simultaneous calls into the various callback functions given by your
/// fuse_operations record.
///
/// If you are using multiple threads, you can enjoy all the parallel execution
/// and interactive response benefits of threads, and you get to enjoy all the
/// benefits of race conditions and locking bugs, too. Ensure that any code used
/// in the callback function of fuse_operations is also thread-safe.
///
/// @param f the FUSE handle
/// @param config loop configuration, may be NULL and defaults will be used then
/// @return see fuse_session_loop()
///
/// See also: fuse_loop()
pub const fuse_loop_mt =
    if (defines.LIBFUSE_BUILT_WITH_VERSIONED_SYMBOLS)
        fuse_loop_mt_fns.fuse_loop_mt
    else
        fuse_loop_mt_fns.fuse_loop_mt_312;
const fuse_loop_mt_fns = struct {
    pub extern fn fuse_loop_mt(f: *Fuse, config: ?*LoopConfig) c_int;
    pub extern fn fuse_loop_mt_312(f: *Fuse, config: ?*LoopConfig) c_int;
};

/// Get the current context
///
/// The context is only valid for the duration of a filesystem
/// operation, and thus must not be stored and used later.
///
/// @return the context
pub extern fn fuse_get_context() ?*Context;

/// Get the current supplementary group IDs for the current request
///
/// Similar to the getgroups(2) system call, except the return value is
/// always the total number of group IDs, even if it is larger than the
/// specified size.
///
/// The current fuse kernel module in linux (as of 2.6.30) doesn't pass
/// the group list to userspace, hence this function needs to parse
/// "/proc/$TID/task/$TID/status" to get the group IDs.
///
/// This feature may not be supported on all operating systems.  In
/// such a case this function will return -ENOSYS.
///
/// @return the total number of supplementary group IDs or -errno on failure
pub extern fn fuse_getgroups(
    /// Size of given array
    size: c_int,
    /// Array of group IDs to be filled in
    list: [*c]gid_t,
) c_int;

/// Check if the current request has already been interrupted
///
/// @return 1 if the request has been interrupted, 0 otherwise
pub extern fn fuse_interrupted() c_int;

/// Invalidates cache for the given path.
///
/// This calls fuse_lowlevel_notify_inval_inode internally.
///
/// @return 0 on successful invalidation, negative error value otherwise.
///         This routine may return -ENOENT to indicate that there was
///         no entry to be invalidated, e.g., because the path has not
///         been seen before or has been forgotten; this should not be
///         considered to be an error.
pub extern fn fuse_invalidate_path(
    f: *Fuse,
    path: [*c]const u8,
) c_int;

/// Start the cleanup thread when using option "remember".
///
/// This is done automatically by fuse_loop_mt()
///
/// @return 0 on success and -1 on error
pub extern fn fuse_start_cleanup_thread(
    /// Pointer for fuse instance
    fuse: *Fuse,
) c_int;

/// Stop the cleanup thread when using option "remember".
///
/// This is done automatically by fuse_loop_mt()
pub extern fn fuse_stop_cleanup_thread(
    /// Pointer for fuse instance
    fuse: *Fuse,
) void;

/// Iterate over cache removing stale entries
/// use in conjunction with "-oremember"
///
/// NOTE: This is already done for the standard sessions
///
/// @return the number of seconds until the next cleanup
pub extern fn fuse_clean_cache(
    /// Pointer for fuse instance
    fuse: *Fuse,
) c_int;

// ----- More detailed API End -----

// ----- Stacking API Begin -----

/// Fuse filesystem object
///
/// This is opaque object represents a filesystem layer
pub const FuseFs = opaque {};

// These functions call the relevant filesystem operation, and return
// the result.
//
// If the operation is not defined, they return -ENOSYS, with the
// exception of fuse_fs_open, fuse_fs_release, fuse_fs_opendir,
// fuse_fs_releasedir and fuse_fs_statfs, which return 0.

pub extern fn fuse_fs_getattr(fs: *FuseFs, path: [*c]const u8, buf: *Stat, fi: *FileInfo) c_int;
pub extern fn fuse_fs_rename(fs: *FuseFs, oldpath: [*c]const u8, newpath: [*c]const u8, flags: c_uint) c_int;
pub extern fn fuse_fs_unlink(fs: *FuseFs, path: [*c]const u8) c_int;
pub extern fn fuse_fs_rmdir(fs: *FuseFs, path: [*c]const u8) c_int;
pub extern fn fuse_fs_symlink(fs: *FuseFs, linkname: [*c]const u8, path: [*c]const u8) c_int;
pub extern fn fuse_fs_link(fs: *FuseFs, oldpath: [*c]const u8, newpath: [*c]const u8) c_int;
pub extern fn fuse_fs_release(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo) c_int;
pub extern fn fuse_fs_open(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo) c_int;
pub extern fn fuse_fs_read(fs: *FuseFs, path: [*c]const u8, buf: [*c]u8, size: usize, off: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_read_buf(fs: *FuseFs, path: [*c]const u8, bufp: ?*[*c]Bufvec, size: usize, off: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_write(fs: *FuseFs, path: [*c]const u8, buf: [*c]const u8, size: usize, off: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_write_buf(fs: *FuseFs, path: [*c]const u8, buf: *Bufvec, off: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_fsync(fs: *FuseFs, path: [*c]const u8, datasync: c_int, fi: *FileInfo) c_int;
pub extern fn fuse_fs_flush(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo) c_int;
pub extern fn fuse_fs_statfs(fs: *FuseFs, path: [*c]const u8, buf: *StatVfs) c_int;
pub extern fn fuse_fs_opendir(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo) c_int;
pub extern fn fuse_fs_readdir(fs: *FuseFs, path: [*c]const u8, buf: ?*anyopaque, filler: FillDir, off: off_t, fi: *FileInfo, flags: ReaddirFlags) c_int;
pub extern fn fuse_fs_fsyncdir(fs: *FuseFs, path: [*c]const u8, datasync: c_int, fi: *FileInfo) c_int;
pub extern fn fuse_fs_releasedir(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo) c_int;
pub extern fn fuse_fs_create(fs: *FuseFs, path: [*c]const u8, mode: mode_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_lock(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo, cmd: c_int, lock: *Flock) c_int;
pub extern fn fuse_fs_flock(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo, op: c_int) c_int;
pub extern fn fuse_fs_chmod(fs: *FuseFs, path: [*c]const u8, mode: mode_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_chown(fs: *FuseFs, path: [*c]const u8, uid: uid_t, gid: gid_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_truncate(fs: *FuseFs, path: [*c]const u8, size: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_utimens(fs: *FuseFs, path: [*c]const u8, tv: *const [2]Timespec, fi: *FileInfo) c_int;
pub extern fn fuse_fs_access(fs: *FuseFs, path: [*c]const u8, mask: c_int) c_int;
pub extern fn fuse_fs_readlink(fs: *FuseFs, path: [*c]const u8, buf: [*c]u8, len: usize) c_int;
pub extern fn fuse_fs_mknod(fs: *FuseFs, path: [*c]const u8, mode: mode_t, rdev: dev_t) c_int;
pub extern fn fuse_fs_mkdir(fs: *FuseFs, path: [*c]const u8, mode: mode_t) c_int;
pub extern fn fuse_fs_setxattr(fs: *FuseFs, path: [*c]const u8, name: [*c]const u8, value: [*c]const u8, size: usize, flags: c_int) c_int;
pub extern fn fuse_fs_getxattr(fs: *FuseFs, path: [*c]const u8, name: [*c]const u8, value: [*c]u8, size: usize) c_int;
pub extern fn fuse_fs_listxattr(fs: *FuseFs, path: [*c]const u8, list: [*c]u8, size: usize) c_int;
pub extern fn fuse_fs_removexattr(fs: *FuseFs, path: [*c]const u8, name: [*c]const u8) c_int;
pub extern fn fuse_fs_bmap(fs: *FuseFs, path: [*c]const u8, blocksize: usize, idx: *u64) c_int;
pub extern fn fuse_fs_ioctl(fs: *FuseFs, path: [*c]const u8, cmd: c_uint, arg: ?*anyopaque, fi: *FileInfo, flags: IoctlFlags, data: ?*anyopaque) c_int;
pub extern fn fuse_fs_poll(fs: *FuseFs, path: [*c]const u8, fi: *FileInfo, ph: *Pollhandle, reventsp: *c_uint) c_int;
pub extern fn fuse_fs_fallocate(fs: *FuseFs, path: [*c]const u8, mode: c_int, offset: off_t, length: off_t, fi: *FileInfo) c_int;
pub extern fn fuse_fs_copy_file_range(fs: *FuseFs, path_in: [*c]const u8, fi_in: *FileInfo, off_in: off_t, path_out: [*c]const u8, fi_out: *FileInfo, off_out: off_t, len: usize, flags: c_int) isize;
pub extern fn fuse_fs_lseek(fs: *FuseFs, path: [*c]const u8, off: off_t, whence: c_int, fi: *FileInfo) off_t;
pub extern fn fuse_fs_statx(fs: *FuseFs, path: [*c]const u8, flags: c_int, mask: c_int, stxbuf: [*c]Statx, fi: *FileInfo) c_int;
pub extern fn fuse_fs_init(fs: *FuseFs, conn: *ConnInfo, cfg: *Config) void;
pub extern fn fuse_fs_destroy(fs: *FuseFs) void;

pub extern fn fuse_notify_poll(ph: *Pollhandle) c_int;

/// Create a new fuse filesystem object
///
/// This is usually called from the factory of a fuse module to create
/// a new instance of a filesystem.
///
/// @return a new filesystem object
pub extern fn fuse_fs_new(
    /// The filesystem operations
    op: *const Operations,
    /// The size of the fuse_operations structure
    op_size: usize,
    /// Initial value for the `private_data`
    /// field of `struct fuse_context`. May be overridden by the
    /// `struct fuse_operations.init` handler.
    private_data: ?*anyopaque,
) ?*FuseFs;

// TODO: FUSE_REGISTER_MODULE/fuse_module_factory_t are not implemented,
// because i am not sure how

/// Get session from fuse object
pub extern fn fuse_get_session(
    f: *Fuse,
) *Session;

/// Open a FUSE file descriptor and set up the mount for the given
/// mountpoint and flags.
///
/// @return the FUSE file descriptor or -1 upon error
pub extern fn fuse_open_channel(
    /// Reference to the mount in the file system
    mountpoint: [*c]const u8,
    /// Mount options
    options: [*c]const u8,
) c_int;

// ----- Stacking API End -----

// ----- fuse.h End ------

// ----- fuse_common.h Begin ------

/// Information about an open file.
///
/// File Handles are created by the open, opendir, and create methods and closed
/// by the release and releasedir methods.  Multiple file handles may be
/// concurrently open for the same file.  Generally, a client will create one
/// file handle per file descriptor, though in some cases multiple file
/// descriptors can share a single file handle.
///
/// Note: This data structure is ABI sensitive, new parameters have to be
///       added within padding/padding2 bits and always below existing
///       parameters.
pub const FileInfo = extern struct {
    /// Open flags. Available in open(), release() and create()
    flags: i32,
    options: packed struct(u32) {
        /// In case of a write operation indicates if this was caused
        /// by a delayed write from the page cache. If so, then the
        /// context's pid, uid, and gid fields will not be valid, and
        /// the *fh* value may not match the *fh* value that would
        /// have been sent with the corresponding individual write
        /// requests if write caching had been disabled.
        writepage: bool,
        /// Can be filled in by open/create, to use direct I/O on this file.
        direct_io: bool,
        /// Can be filled in by open and opendir. It signals the kernel that any
        /// currently cached data (ie., data that the filesystem provided the
        /// last time the file/directory was open) need not be invalidated when
        /// the file/directory is closed.
        keep_cache: bool,
        /// Indicates a flush operation.  Set in flush operation, also
        /// maybe set in highlevel lock operation and lowlevel release
        /// operation.
        flush: bool,
        /// Can be filled in by open, to indicate that the file is not
        /// seekable.
        nonseekable: bool,
        /// Indicates that flock locks for this file should be
        /// released.  If set, lock_owner shall contain a valid value.
        /// May only be set in ->release().
        flock_release: bool,
        /// Can be filled in by opendir. It signals the kernel to
        /// enable caching of entries returned by readdir().  Has no
        /// effect when set in other contexts (in particular it does
        /// nothing when set by open()).
        cache_readdir: bool,
        /// Can be filled in by open, to indicate that flush is not needed
        /// on close.
        noflush: bool,
        /// Can be filled by open/create, to allow parallel direct writes on this
        /// file
        parallel_direct_writes: bool,
        /// Set in open, create and write when KILLPRIV_V2 was negotiated and
        /// the application issuing the syscall lacks CAP_FSETID; the
        /// filesystem's own privileges do not matter. The filesystem then
        /// has to remove setuid/setgid bits.
        kill_suidgid: bool,
        _: u22,
    },
    _: u64,
    fh: u64,
    lock_owner: u64,
    poll_events: u32,
    backing_id: i32,
    compat_flags: u64,
    reserved: [2]u64,

    comptime {
        std.debug.assert(@sizeOf(FileInfo) == 64);
        std.debug.assert(@alignOf(FileInfo) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(FileInfo, "flags") == 0);
        std.debug.assert(@offsetOf(FileInfo, "options") == 4);
        std.debug.assert(@offsetOf(FileInfo, "fh") == 16);
        std.debug.assert(@offsetOf(FileInfo, "lock_owner") == 24);
        std.debug.assert(@offsetOf(FileInfo, "poll_events") == 32);
        std.debug.assert(@offsetOf(FileInfo, "backing_id") == 36);
        std.debug.assert(@offsetOf(FileInfo, "compat_flags") == 40);
        std.debug.assert(@offsetOf(FileInfo, "reserved") == 48);
        std.debug.assert(@sizeOf(@FieldType(FileInfo, "options")) == 4);
        std.debug.assert(@alignOf(@FieldType(FileInfo, "options")) == 4);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "writepage") == 0);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "direct_io") == 1);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "keep_cache") == 2);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "flush") == 3);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "nonseekable") == 4);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "flock_release") == 5);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "cache_readdir") == 6);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "noflush") == 7);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "parallel_direct_writes") == 8);
        std.debug.assert(@bitOffsetOf(@FieldType(FileInfo, "options"), "kill_suidgid") == 9);
    }
};

/// Configuration parameters passed to fuse_session_loop_mt() and
/// fuse_loop_mt().
/// For FUSE API versions less than 312, use a public struct
/// fuse_loop_config in applications and struct fuse_loop_config_v1
/// is used in library (i.e., libfuse.so). These two structs are binary
/// compatible in earlier API versions and can be linked.
/// Deprecated and replaced by a newer private struct in FUSE API
/// version 312 (FUSE_MAKE_VERSION(3, 12)).
pub const LoopConfigV1 = extern struct {
    /// Whether to use separate device fds for each thread
    /// (may increase performance)
    clone_fd: c_int,

    /// The maximum number of available worker threads before they
    /// start to get deleted when they become idle. If not
    /// specified, the default is 10.
    ///
    /// Adjusting this has performance implications; a very small number
    /// of threads in the pool will cause a lot of thread creation and
    /// deletion overhead and performance may suffer. When set to 0, a new
    /// thread will be created to service every operation.
    max_idle_threads: c_uint,

    comptime {
        std.debug.assert(@sizeOf(LoopConfigV1) == 8);
        std.debug.assert(@alignOf(LoopConfigV1) == 4);
        std.debug.assert(@offsetOf(LoopConfigV1, "clone_fd") == 0);
        std.debug.assert(@offsetOf(LoopConfigV1, "max_idle_threads") == 4);
    }
};

/// New loop config (FUSE API >= 3.12). Layout is private to libfuse
/// (`lib/fuse_i.h`); use the `fuse_loop_cfg_*` accessors.
pub const LoopConfig = opaque {};

/// Capability bits negotiated between the kernel and the filesystem.
pub const Capabilities = packed struct(u64) {
    /// Indicates that the filesystem supports asynchronous read requests.
    ///
    /// If this capability is not requested/available, the kernel will
    /// ensure that there is at most one pending read request per
    /// file-handle at any time, and will attempt to order read requests by
    /// increasing offset.
    ///
    /// This feature is enabled by default when supported by the kernel.
    ASYNC_READ: bool = false,
    /// Indicates that the filesystem supports "remote" locking.
    ///
    /// This feature is enabled by default when supported by the kernel,
    /// and if getlk() and setlk() handlers are implemented.
    POSIX_LOCKS: bool = false,
    __unused_bit2: u1 = 0,
    /// Indicates that the filesystem supports the O_TRUNC open flag.  If
    /// disabled, and an application specifies O_TRUNC, fuse first calls
    /// truncate() and then open() with O_TRUNC filtered out.
    ///
    /// This feature is enabled by default when supported by the kernel.
    ATOMIC_O_TRUNC: bool = false,
    /// Indicates that the filesystem supports lookups of "." and "..".
    ///
    /// When this flag is set, the filesystem must be prepared to receive requests
    /// for invalid inodes (i.e., for which a FORGET request was received or
    /// which have been used in a previous instance of the filesystem daemon) and
    /// must not reuse node-ids (even when setting generation numbers).
    ///
    /// This feature is disabled by default.
    EXPORT_SUPPORT: bool = false,
    __unused_bit5: u1 = 0,
    /// Indicates that the kernel should not apply the umask to the
    /// file mode on create operations.
    ///
    /// This feature is disabled by default.
    DONT_MASK: bool = false,
    /// Indicates that libfuse should try to use splice() when writing to
    /// the fuse device. This may improve performance.
    ///
    /// This feature is disabled by default.
    SPLICE_WRITE: bool = false,
    /// Indicates that libfuse should try to move pages instead of copying when
    /// writing to / reading from the fuse device. This may improve performance.
    ///
    /// This feature is disabled by default.
    SPLICE_MOVE: bool = false,
    /// Indicates that libfuse should try to use splice() when reading from
    /// the fuse device. This may improve performance.
    ///
    /// This feature is enabled by default when supported by the kernel and
    /// if the filesystem implements a write_buf() handler.
    SPLICE_READ: bool = false,
    /// If set, the calls to flock(2) will be emulated using POSIX locks and must
    /// then be handled by the filesystem's setlock() handler.
    ///
    /// If not set, flock(2) calls will be handled by the FUSE kernel module
    /// internally (so any access that does not go through the kernel cannot be taken
    /// into account).
    ///
    /// This feature is enabled by default when supported by the kernel and
    /// if the filesystem implements a flock() handler.
    FLOCK_LOCKS: bool = false,
    /// Indicates that the filesystem supports ioctl's on directories.
    ///
    /// This feature is enabled by default when supported by the kernel.
    IOCTL_DIR: bool = false,
    /// Traditionally, while a file is open the FUSE kernel module only
    /// asks the filesystem for an update of the file's attributes when a
    /// client attempts to read beyond EOF. This is unsuitable for
    /// e.g. network filesystems, where the file contents may change
    /// without the kernel knowing about it.
    ///
    /// If this flag is set, FUSE will check the validity of the attributes
    /// on every read. If the attributes are no longer valid (i.e., if the
    /// *attr_timeout* passed to fuse_reply_attr() or set in `struct
    /// fuse_entry_param` has passed), it will first issue a `getattr`
    /// request. If the new mtime differs from the previous value, any
    /// cached file *contents* will be invalidated as well.
    ///
    /// This flag should always be set when available. If all file changes
    /// go through the kernel, *attr_timeout* should be set to a very large
    /// number to avoid unnecessary getattr() calls.
    ///
    /// This feature is enabled by default when supported by the kernel.
    AUTO_INVAL_DATA: bool = false,
    /// Indicates that the filesystem supports readdirplus.
    ///
    /// This feature is enabled by default when supported by the kernel and if the
    /// filesystem implements a readdirplus() handler.
    READDIRPLUS: bool = false,
    /// Indicates that the filesystem supports adaptive readdirplus.
    ///
    /// If FUSE_CAP_READDIRPLUS is not set, this flag has no effect.
    ///
    /// If FUSE_CAP_READDIRPLUS is set and this flag is not set, the kernel
    /// will always issue readdirplus() requests to retrieve directory
    /// contents.
    ///
    /// If FUSE_CAP_READDIRPLUS is set and this flag is set, the kernel
    /// will issue both readdir() and readdirplus() requests, depending on
    /// how much information is expected to be required.
    ///
    /// As of Linux 4.20, the algorithm is as follows: when userspace
    /// starts to read directory entries, issue a READDIRPLUS request to
    /// the filesystem. If any entry attributes have been looked up by the
    /// time userspace requests the next batch of entries continue with
    /// READDIRPLUS, otherwise switch to plain READDIR.  This will reasult
    /// in eg plain "ls" triggering READDIRPLUS first then READDIR after
    /// that because it doesn't do lookups.  "ls -l" should result in all
    /// READDIRPLUS, except if dentries are already cached.
    ///
    /// This feature is enabled by default when supported by the kernel and
    /// if the filesystem implements both a readdirplus() and a readdir()
    /// handler.
    READDIRPLUS_AUTO: bool = false,
    /// Indicates that the filesystem supports asynchronous direct I/O submission.
    ///
    /// If this capability is not requested/available, the kernel will ensure that
    /// there is at most one pending read and one pending write request per direct
    /// I/O file-handle at any time.
    ///
    /// This feature is enabled by default when supported by the kernel.
    ASYNC_DIO: bool = false,
    /// Indicates that writeback caching should be enabled. This means that
    /// individual write request may be buffered and merged in the kernel
    /// before they are send to the filesystem.
    ///
    /// This feature is disabled by default.
    WRITEBACK_CACHE: bool = false,
    /// Indicates support for zero-message opens. If this flag is set in
    /// the `capable` field of the `fuse_conn_info` structure, then the
    /// filesystem may return `ENOSYS` from the open() handler to indicate
    /// success. Further attempts to open files will be handled in the
    /// kernel. (If this flag is not set, returning ENOSYS will be treated
    /// as an error and signaled to the caller).
    ///
    /// Setting this flag in the `want` field enables this behavior automatically
    /// within libfuse for low level API users. If non-low level users wish to have
    /// this behavior you must return `ENOSYS` from the open() handler on supporting
    /// kernels.
    NO_OPEN_SUPPORT: bool = false,
    /// Indicates support for parallel directory operations. If this flag
    /// is unset, the FUSE kernel module will ensure that lookup() and
    /// readdir() requests are never issued concurrently for the same
    /// directory.
    PARALLEL_DIROPS: bool = false,
    /// Indicates support for POSIX ACLs.
    ///
    /// If this feature is enabled, the kernel will cache and have
    /// responsibility for enforcing ACLs. ACL will be stored as xattrs and
    /// passed to userspace, which is responsible for updating the ACLs in
    /// the filesystem, keeping the file mode in sync with the ACL, and
    /// ensuring inheritance of default ACLs when new filesystem nodes are
    /// created. Note that this requires that the file system is able to
    /// parse and interpret the xattr representation of ACLs.
    ///
    /// Enabling this feature implicitly turns on the
    /// ``default_permissions`` mount option (even if it was not passed to
    /// mount(2)).
    ///
    /// This feature is disabled by default.
    POSIX_ACL: bool = false,
    /// Indicates that the filesystem is responsible for unsetting
    /// setuid and setgid bits when a file is written, truncated, or
    /// its owner is changed.
    ///
    /// This feature is disabled by default.
    HANDLE_KILLPRIV: bool = false,
    /// Indicates that the filesystem is responsible for unsetting
    /// setuid and setgid bit and additionally cap (stored as xattr) when a
    /// file is written, truncated, or its owner is changed.
    /// Upon write/truncate suid/sgid is only killed if caller
    /// does not have CAP_FSETID. Additionally upon
    /// write/truncate sgid is killed only if file has group
    /// execute permission. (Same as Linux VFS behavior).
    /// KILLPRIV_V2 requires handling of
    ///   - FUSE_OPEN_KILL_SUIDGID (set in struct fuse_create_in::open_flags)
    ///   - FATTR_KILL_SUIDGID (set in struct fuse_setattr_in::valid)
    ///   - FUSE_WRITE_KILL_SUIDGID (set in struct fuse_write_in::write_flags)
    ///
    /// This feature is disabled by default.
    HANDLE_KILLPRIV_V2: bool = false,
    __unused_bit22: u1 = 0,
    /// Indicates that the kernel supports caching symlinks in its page cache.
    ///
    /// When this feature is enabled, symlink targets are saved in the page cache.
    /// You can invalidate a cached link by calling:
    /// `fuse_lowlevel_notify_inval_inode(se, ino, 0, 0);`
    ///
    /// This feature is disabled by default.
    /// If the kernel supports it (>= 4.20), you can enable this feature by
    /// setting this flag in the `want` field of the `fuse_conn_info` structure.
    CACHE_SYMLINKS: bool = false,
    /// Indicates support for zero-message opendirs. If this flag is set in
    /// the `capable` field of the `fuse_conn_info` structure, then the filesystem
    /// may return `ENOSYS` from the opendir() handler to indicate success. Further
    /// opendir and releasedir messages will be handled in the kernel. (If this
    /// flag is not set, returning ENOSYS will be treated as an error and signalled
    /// to the caller.)
    ///
    /// Setting this flag in the `want` field enables this behavior automatically
    /// within libfuse for low level API users.  If non-low level users with to have
    /// this behavior you must return `ENOSYS` from the opendir() handler on
    /// supporting kernels.
    NO_OPENDIR_SUPPORT: bool = false,
    /// Indicates support for invalidating cached pages only on explicit request.
    ///
    /// If this flag is set in the `capable` field of the `fuse_conn_info` structure,
    /// then the FUSE kernel module supports invalidating cached pages only on
    /// explicit request by the filesystem through fuse_lowlevel_notify_inval_inode()
    /// or fuse_invalidate_path().
    ///
    /// By setting this flag in the `want` field of the `fuse_conn_info` structure,
    /// the filesystem is responsible for invalidating cached pages through explicit
    /// requests to the kernel.
    ///
    /// Note that setting this flag does not prevent the cached pages from being
    /// flushed by OS itself and/or through user actions.
    ///
    /// Note that if both FUSE_CAP_EXPLICIT_INVAL_DATA and FUSE_CAP_AUTO_INVAL_DATA
    /// are set in the `capable` field of the `fuse_conn_info` structure then
    /// FUSE_CAP_AUTO_INVAL_DATA takes precedence.
    ///
    /// This feature is disabled by default.
    EXPLICIT_INVAL_DATA: bool = false,
    /// Indicates support that dentries can be expired.
    ///
    /// Expiring dentries, instead of invalidating them, makes a difference for
    /// overmounted dentries, where plain invalidation would detach all submounts
    /// before dropping the dentry from the cache. If only expiry is set on the
    /// dentry, then any overmounts are left alone and until ->d_revalidate()
    /// is called.
    ///
    /// Note: ->d_revalidate() is not called for the case of following a submount,
    /// so invalidation will only be triggered for the non-overmounted case.
    /// The dentry could also be mounted in a different mount instance, in which case
    /// any submounts will still be detached.
    EXPIRE_ONLY: bool = false,
    /// Indicates that an extended 'struct fuse_setxattr' is used by the kernel
    /// side - extra_flags are passed, which are used (as of now by acl) processing.
    /// For example FUSE_SETXATTR_ACL_KILL_SGID might be set.
    SETXATTR_EXT: bool = false,
    /// Files opened with FUSE_DIRECT_IO do not support MAP_SHARED mmap. This restriction
    /// is relaxed through FUSE_CAP_DIRECT_IO_RELAX (kernel flag: FUSE_DIRECT_IO_RELAX).
    /// MAP_SHARED is disabled by default for FUSE_DIRECT_IO, as this flag can be used to
    /// ensure coherency between mount points (or network clients) and with kernel page
    /// cache as enforced by mmap that cannot be guaranteed anymore.
    DIRECT_IO_ALLOW_MMAP: bool = false,
    /// Indicates support for passthrough mode access for read/write operations.
    ///
    /// If this flag is set in the `capable` field of the `fuse_conn_info`
    /// structure, then the FUSE kernel module supports redirecting read/write
    /// operations to the backing file instead of letting them to be handled
    /// by the FUSE daemon.
    ///
    /// This feature is disabled by default.
    PASSTHROUGH: bool = false,
    /// Indicates that the file system cannot handle NFS export
    ///
    /// If this flag is set NFS export and name_to_handle_at
    /// is not going to work at all and will fail with EOPNOTSUPP.
    NO_EXPORT_SUPPORT: bool = false,
    /// Indicates support for io-uring between fuse-server and fuse-client
    OVER_IO_URING: bool = false,
    /// Reserved for future capabilities.
    __RESERVED: u32 = 0,

    comptime {
        std.debug.assert(@sizeOf(Capabilities) == 8);
        std.debug.assert(@alignOf(Capabilities) == @alignOf(u64));
        std.debug.assert(@bitOffsetOf(Capabilities, "ASYNC_READ") == 0);
        std.debug.assert(@bitOffsetOf(Capabilities, "POSIX_LOCKS") == 1);
        std.debug.assert(@bitOffsetOf(Capabilities, "__unused_bit2") == 2);
        std.debug.assert(@bitOffsetOf(Capabilities, "ATOMIC_O_TRUNC") == 3);
        std.debug.assert(@bitOffsetOf(Capabilities, "EXPORT_SUPPORT") == 4);
        std.debug.assert(@bitOffsetOf(Capabilities, "__unused_bit5") == 5);
        std.debug.assert(@bitOffsetOf(Capabilities, "DONT_MASK") == 6);
        std.debug.assert(@bitOffsetOf(Capabilities, "SPLICE_WRITE") == 7);
        std.debug.assert(@bitOffsetOf(Capabilities, "SPLICE_MOVE") == 8);
        std.debug.assert(@bitOffsetOf(Capabilities, "SPLICE_READ") == 9);
        std.debug.assert(@bitOffsetOf(Capabilities, "FLOCK_LOCKS") == 10);
        std.debug.assert(@bitOffsetOf(Capabilities, "IOCTL_DIR") == 11);
        std.debug.assert(@bitOffsetOf(Capabilities, "AUTO_INVAL_DATA") == 12);
        std.debug.assert(@bitOffsetOf(Capabilities, "READDIRPLUS") == 13);
        std.debug.assert(@bitOffsetOf(Capabilities, "READDIRPLUS_AUTO") == 14);
        std.debug.assert(@bitOffsetOf(Capabilities, "ASYNC_DIO") == 15);
        std.debug.assert(@bitOffsetOf(Capabilities, "WRITEBACK_CACHE") == 16);
        std.debug.assert(@bitOffsetOf(Capabilities, "NO_OPEN_SUPPORT") == 17);
        std.debug.assert(@bitOffsetOf(Capabilities, "PARALLEL_DIROPS") == 18);
        std.debug.assert(@bitOffsetOf(Capabilities, "POSIX_ACL") == 19);
        std.debug.assert(@bitOffsetOf(Capabilities, "HANDLE_KILLPRIV") == 20);
        std.debug.assert(@bitOffsetOf(Capabilities, "HANDLE_KILLPRIV_V2") == 21);
        std.debug.assert(@bitOffsetOf(Capabilities, "__unused_bit22") == 22);
        std.debug.assert(@bitOffsetOf(Capabilities, "CACHE_SYMLINKS") == 23);
        std.debug.assert(@bitOffsetOf(Capabilities, "NO_OPENDIR_SUPPORT") == 24);
        std.debug.assert(@bitOffsetOf(Capabilities, "EXPLICIT_INVAL_DATA") == 25);
        std.debug.assert(@bitOffsetOf(Capabilities, "EXPIRE_ONLY") == 26);
        std.debug.assert(@bitOffsetOf(Capabilities, "SETXATTR_EXT") == 27);
        std.debug.assert(@bitOffsetOf(Capabilities, "DIRECT_IO_ALLOW_MMAP") == 28);
        std.debug.assert(@bitOffsetOf(Capabilities, "PASSTHROUGH") == 29);
        std.debug.assert(@bitOffsetOf(Capabilities, "NO_EXPORT_SUPPORT") == 30);
        std.debug.assert(@bitOffsetOf(Capabilities, "OVER_IO_URING") == 31);
        std.debug.assert(@bitOffsetOf(Capabilities, "__RESERVED") == 32);
    }
};

pub const IoctlFlags = packed struct(u32) {
    /// 32-bit compat ioctl on a 64-bit machine.
    COMPAT: bool = false,
    /// Not restricted to well-formed ioctls; retry allowed.
    UNRESTRICTED: bool = false,
    /// Retry with new iovecs
    RETRY: bool = false,
    __unused_bit3: u1 = 0,
    /// Is a directory
    DIR: bool = false,
    /// x32 compat ioctl on 64bit machine (64bit time_t)
    COMPAT_X32: bool = false,
    __reserved: u26 = 0,

    /// Maximum of in_iovecs + out_iovecs
    pub const MAX_IOV = 256;

    comptime {
        std.debug.assert(@sizeOf(IoctlFlags) == 4);
        std.debug.assert(@alignOf(IoctlFlags) == 4);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "COMPAT") == 0);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "UNRESTRICTED") == 1);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "RETRY") == 2);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "__unused_bit3") == 3);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "DIR") == 4);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "COMPAT_X32") == 5);
        std.debug.assert(@bitOffsetOf(IoctlFlags, "__reserved") == 6);
    }
};

/// Connection information, passed to the ->init() method
///
/// Some of the elements are read-write, these can be changed to
/// indicate the value requested by the filesystem.  The requested
/// value must usually be smaller than the indicated value.
///
/// Note: The `capable` and `want` fields are limited to 32 bits for
/// ABI compatibility. For full 64-bit capability support, use the
/// `capable_ext` and `want_ext` fields instead.
pub const ConnInfo = extern struct {
    /// Major version of the protocol (read-only)
    proto_major: u32,
    /// Minor version of the protocol (read-only)
    proto_minor: u32,
    /// Maximum size of the write buffer
    max_write: u32,
    /// Maximum size of read requests. A value of zero indicates no
    /// limit. However, even if the filesystem does not specify a
    /// limit, the maximum size of read requests will still be
    /// limited by the kernel.
    ///
    /// NOTE: For the time being, the maximum size of read requests
    /// must be set both here *and* passed to fuse_session_new()
    /// using the ``-o max_read=<n>`` mount option. At some point
    /// in the future, specifying the mount option will no longer
    /// be necessary.
    max_read: u32,
    /// Maximum readahead
    max_readahead: u32,
    /// Capability flags that the kernel supports (read-only)
    ///
    /// Deprecated left over for ABI compatibility, use capable_ext
    capable: u32,
    /// Capability flags that the filesystem wants to enable.
    ///
    /// libfuse attempts to initialize this field with
    /// reasonable default values before calling the init() handler.
    ///
    /// Deprecated left over for ABI compatibility.
    /// Use want_ext with the helper functions
    /// fuse_set_feature_flag() / fuse_unset_feature_flag()
    want: u32,
    /// Maximum number of pending "background" requests. A
    /// background request is any type of request for which the
    /// total number is not limited by other means. As of kernel
    /// 4.8, only two types of requests fall into this category:
    ///
    ///   1. Read-ahead requests
    ///   2. Asynchronous direct I/O requests
    ///
    /// Read-ahead requests are generated (if max_readahead is
    /// non-zero) by the kernel to preemptively fill its caches
    /// when it anticipates that userspace will soon read more
    /// data.
    ///
    /// Asynchronous direct I/O requests are generated if
    /// FUSE_CAP_ASYNC_DIO is enabled and userspace submits a large
    /// direct I/O request. In this case the kernel will internally
    /// split it up into multiple smaller requests and submit them
    /// to the filesystem concurrently.
    ///
    /// Note that the following requests are *not* background
    /// requests: writeback requests (limited by the kernel's
    /// flusher algorithm), regular (i.e., synchronous and
    /// buffered) userspace read/write requests (limited to one per
    /// thread), asynchronous read requests (Linux's io_submit(2)
    /// call actually blocks, so these are also limited to one per
    /// thread).
    max_background: u32,
    /// Kernel congestion threshold parameter. If the number of pending
    /// background requests exceeds this number, the FUSE kernel module will
    /// mark the filesystem as "congested". This instructs the kernel to
    /// expect that queued requests will take some time to complete, and to
    /// adjust its algorithms accordingly (e.g. by putting a waiting thread
    /// to sleep instead of using a busy-loop).
    congestion_threshold: u32,
    /// When FUSE_CAP_WRITEBACK_CACHE is enabled, the kernel is responsible
    /// for updating mtime and ctime when write requests are received. The
    /// updated values are passed to the filesystem with setattr() requests.
    /// However, if the filesystem does not support the full resolution of
    /// the kernel timestamps (nanoseconds), the mtime and ctime values used
    /// by kernel and filesystem will differ (and result in an apparent
    /// change of times after a cache flush).
    ///
    /// To prevent this problem, this variable can be used to inform the
    /// kernel about the timestamp granularity supported by the file-system.
    /// The value should be power of 10.  The default is 1, i.e. full
    /// nano-second resolution. Filesystems supporting only second resolution
    /// should set this to 1000000000.
    time_gran: u32,
    /// When FUSE_CAP_PASSTHROUGH is enabled, this is the maximum allowed
    /// stacking depth of the backing files.  In current kernel, the maximum
    /// allowed stack depth if FILESYSTEM_MAX_STACK_DEPTH (2), which includes
    /// the FUSE passthrough layer, so the maximum stacking depth for backing
    /// files is 1.
    ///
    /// The default is FUSE_BACKING_STACKED_UNDER (0), meaning that the
    /// backing files cannot be on a stacked filesystem, but another stacked
    /// filesystem can be stacked over this FUSE passthrough filesystem.
    ///
    /// Set this to FUSE_BACKING_STACKED_OVER (1) if backing files may be on
    /// a stacked filesystem, such as overlayfs or another FUSE passthrough.
    /// In this configuration, another stacked filesystem cannot be stacked
    /// over this FUSE passthrough filesystem.
    max_backing_stack_depth: u32,
    options: packed struct(u32) {
        /// Disable FUSE_INTERRUPT requests.
        ///
        /// Enable `no_interrupt` option to:
        /// 1) Avoid unnecessary locking operations and list operations,
        /// 2) Return ENOSYS for the reply of FUSE_INTERRUPT request to
        /// inform the kernel not to send the FUSE_INTERRUPT request.
        no_interrupt: bool,
        /// reserved bits for future use
        padding: u31,
    },
    // Extended capability flags that the kernel supports (read-only)
    // This field provides full 64-bit capability support.
    capable_ext: Capabilities,
    /// Extended capability flags that the filesystem wants to enable.
    /// This field provides full 64-bit capability support.
    ///
    /// Don't set this field directly, but use the helper functions
    /// fuse_set_feature_flag() / fuse_unset_feature_flag()
    want_ext: Capabilities,
    /// Request timeout (in seconds). If the request is not answered by
    /// this timeout, the connection will be aborted by the kernel.
    request_timeout: u16,
    /// For future use.
    reserved: [31]u16,

    comptime {
        std.debug.assert(@sizeOf(ConnInfo) == 128);
        std.debug.assert(@alignOf(ConnInfo) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(ConnInfo, "proto_major") == 0);
        std.debug.assert(@offsetOf(ConnInfo, "proto_minor") == 4);
        std.debug.assert(@offsetOf(ConnInfo, "max_write") == 8);
        std.debug.assert(@offsetOf(ConnInfo, "max_read") == 12);
        std.debug.assert(@offsetOf(ConnInfo, "max_readahead") == 16);
        std.debug.assert(@offsetOf(ConnInfo, "capable") == 20);
        std.debug.assert(@offsetOf(ConnInfo, "want") == 24);
        std.debug.assert(@offsetOf(ConnInfo, "max_background") == 28);
        std.debug.assert(@offsetOf(ConnInfo, "congestion_threshold") == 32);
        std.debug.assert(@offsetOf(ConnInfo, "time_gran") == 36);
        std.debug.assert(@offsetOf(ConnInfo, "max_backing_stack_depth") == 40);
        std.debug.assert(@offsetOf(ConnInfo, "options") == 44);
        std.debug.assert(@offsetOf(ConnInfo, "capable_ext") == 48);
        std.debug.assert(@offsetOf(ConnInfo, "want_ext") == 56);
        std.debug.assert(@offsetOf(ConnInfo, "request_timeout") == 64);
        std.debug.assert(@offsetOf(ConnInfo, "reserved") == 66);
        std.debug.assert(@sizeOf(@FieldType(ConnInfo, "options")) == 4);
        std.debug.assert(@alignOf(@FieldType(ConnInfo, "options")) == 4);
        std.debug.assert(@bitOffsetOf(@FieldType(ConnInfo, "options"), "no_interrupt") == 0);
        std.debug.assert(@bitOffsetOf(@FieldType(ConnInfo, "options"), "padding") == 1);
    }
};

pub const Session = opaque {};

pub const Pollhandle = opaque {};

pub const ConnInfoOpts = opaque {};

/// This function parses several command-line options that can be used
/// to override elements of struct fuse_conn_info. The pointer returned
/// by this function should be passed to the
/// fuse_apply_conn_info_opts() method by the file system's init()
/// handler.
///
/// Before using this function, think twice if you really want these
/// parameters to be adjustable from the command line. In most cases,
/// they should be determined by the file system internally.
///
/// The following options are recognized:
///
///   -o max_write=N         sets conn->max_write
///   -o max_readahead=N     sets conn->max_readahead
///   -o max_background=N    sets conn->max_background
///   -o congestion_threshold=N  sets conn->congestion_threshold
///   -o async_read          sets FUSE_CAP_ASYNC_READ in conn->want
///   -o sync_read           unsets FUSE_CAP_ASYNC_READ in conn->want
///   -o atomic_o_trunc      sets FUSE_CAP_ATOMIC_O_TRUNC in conn->want
///   -o no_remote_lock      Equivalent to -o no_remote_flock,no_remote_posix_lock
///   -o no_remote_flock     Unsets FUSE_CAP_FLOCK_LOCKS in conn->want
///   -o no_remote_posix_lock  Unsets FUSE_CAP_POSIX_LOCKS in conn->want
///   -o [no_]splice_write     (un-)sets FUSE_CAP_SPLICE_WRITE in conn->want
///   -o [no_]splice_move      (un-)sets FUSE_CAP_SPLICE_MOVE in conn->want
///   -o [no_]splice_read      (un-)sets FUSE_CAP_SPLICE_READ in conn->want
///   -o [no_]auto_inval_data  (un-)sets FUSE_CAP_AUTO_INVAL_DATA in conn->want
///   -o readdirplus=no        unsets FUSE_CAP_READDIRPLUS in conn->want
///   -o readdirplus=yes       sets FUSE_CAP_READDIRPLUS and unsets
///                            FUSE_CAP_READDIRPLUS_AUTO in conn->want
///   -o readdirplus=auto      sets FUSE_CAP_READDIRPLUS and
///                            FUSE_CAP_READDIRPLUS_AUTO in conn->want
///   -o [no_]async_dio        (un-)sets FUSE_CAP_ASYNC_DIO in conn->want
///   -o [no_]writeback_cache  (un-)sets FUSE_CAP_WRITEBACK_CACHE in conn->want
///   -o time_gran=N           sets conn->time_gran
///
/// Known options will be removed from *args*, unknown options will be
/// passed through unchanged.
///
/// @return parsed options
pub extern fn fuse_parse_conn_info_opts(
    /// Argument vector (input+output)
    args: *Args,
) ?*ConnInfoOpts;

/// This function applies the (parsed) parameters in *opts* to the
/// *conn* pointer. It may modify the following fields: wants,
/// max_write, max_readahead, congestion_threshold, max_background,
/// time_gran. A field is only set (or unset) if the corresponding
/// option has been explicitly set.
pub extern fn fuse_apply_conn_info_opts(
    opts: *ConnInfoOpts,
    conn: *ConnInfo,
) void;

/// Go into the background
///
/// @return 0 on success, -1 on failure
pub extern fn fuse_daemonize(
    /// If true, stay in the foreground
    foreground: c_int,
) c_int;

/// Get the version of the library
///
/// @return the version
pub extern fn fuse_version() c_int;

/// Get the full package version string of the library
///
/// @return the package version
pub extern fn fuse_pkgversion() [*c]const u8;

/// Destroy poll handle
pub extern fn fuse_pollhandle_destroy(
    /// The poll handle
    ph: *Pollhandle,
) void;

// ----- Data buffer Begin -----

/// Single data buffer
///
/// Generic data buffer for I/O, extended attributes, etc...
/// Data may be supplied as a memory pointer or as a file descriptor
pub const Buf = extern struct {
    /// Size of data in bytes
    size: usize,
    /// Buffer flags
    flags: Flags,
    /// Memory pointer
    ///
    /// Used unless FUSE_BUF_IS_FD flag is set.
    mem: ?*anyopaque,
    /// File descriptor
    ///
    /// Used if FUSE_BUF_IS_FD flag is set.
    fd: c_int,
    /// File position
    ///
    /// Used if FUSE_BUF_FD_SEEK flag is set.
    pos: off_t,
    /// Size of memory pointer
    ///
    /// Used only if mem was internally allocated.
    /// Not used if mem was user-provided.
    mem_size: usize,

    /// Buffer flags
    pub const Flags = packed struct(u32) {
        __unused_bit0: u1 = 0,
        /// Buffer contains a file descriptor
        ///
        /// If this flag is set, the .fd field is valid, otherwise the
        /// .mem fields is valid.
        IS_FD: bool = false,
        /// Seek on the file descriptor
        ///
        /// If this flag is set then the .pos field is valid and is
        /// used to seek to the given offset before performing
        /// operation on file descriptor.
        FD_SEEK: bool = false,
        /// Retry operation on file descriptor
        ///
        /// If this flag is set then retry operation on file descriptor
        /// until .size bytes have been copied or an error or EOF is
        /// detected.
        FD_RETRY: bool = false,
        __reserved: u28 = 0,

        comptime {
            std.debug.assert(@sizeOf(Flags) == 4);
            std.debug.assert(@alignOf(Flags) == 4);
            std.debug.assert(@bitOffsetOf(Flags, "__unused_bit0") == 0);
            std.debug.assert(@bitOffsetOf(Flags, "IS_FD") == 1);
            std.debug.assert(@bitOffsetOf(Flags, "FD_SEEK") == 2);
            std.debug.assert(@bitOffsetOf(Flags, "FD_RETRY") == 3);
            std.debug.assert(@bitOffsetOf(Flags, "__reserved") == 4);
        }
    };

    /// Buffer copy flags
    pub const CopyFlags = packed struct(u32) {
        __unused_bit0: u1 = 0,
        /// Don't use splice(2)
        ///
        /// Always fall back to using read and write instead of
        /// splice(2) to copy data from one file descriptor to another.
        ///
        /// If this flag is not set, then only fall back if splice is
        /// unavailable.
        NO_SPLICE: bool = false,
        /// Force splice
        ///
        /// Always use splice(2) to copy data from one file descriptor
        /// to another.  If splice is not available, return -EINVAL.
        FORCE_SPLICE: bool = false,
        /// Try to move data with splice.
        ///
        /// If splice is used, try to move pages from the source to the
        /// destination instead of copying.  See documentation of
        /// SPLICE_F_MOVE in splice(2) man page.
        SPLICE_MOVE: bool = false,
        /// Don't block on the pipe when copying data with splice
        ///
        /// Makes the operations on the pipe non-blocking (if the pipe
        /// is full or empty).  See SPLICE_F_NONBLOCK in the splice(2)
        /// man page.
        SPLICE_NONBLOCK: bool = false,
        __reserved: u27 = 0,

        comptime {
            std.debug.assert(@sizeOf(CopyFlags) == 4);
            std.debug.assert(@alignOf(CopyFlags) == 4);
            std.debug.assert(@bitOffsetOf(CopyFlags, "__unused_bit0") == 0);
            std.debug.assert(@bitOffsetOf(CopyFlags, "NO_SPLICE") == 1);
            std.debug.assert(@bitOffsetOf(CopyFlags, "FORCE_SPLICE") == 2);
            std.debug.assert(@bitOffsetOf(CopyFlags, "SPLICE_MOVE") == 3);
            std.debug.assert(@bitOffsetOf(CopyFlags, "SPLICE_NONBLOCK") == 4);
            std.debug.assert(@bitOffsetOf(CopyFlags, "__reserved") == 5);
        }
    };

    comptime {
        std.debug.assert(@sizeOf(Buf) == if (is_x86_64_arch) 48 else 28);
        std.debug.assert(@alignOf(Buf) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Buf, "size") == 0);
        std.debug.assert(@offsetOf(Buf, "flags") == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Buf, "mem") == if (is_x86_64_arch) 16 else 8);
        std.debug.assert(@offsetOf(Buf, "fd") == if (is_x86_64_arch) 24 else 12);
        std.debug.assert(@offsetOf(Buf, "pos") == if (is_x86_64_arch) 32 else 16);
        std.debug.assert(@offsetOf(Buf, "mem_size") == if (is_x86_64_arch) 40 else 24);
    }
};

/// Data buffer vector
///
/// An array of data buffers, each containing a memory pointer or a
/// file descriptor.
///
/// Allocate dynamically to add more than one buffer.
pub const Bufvec = extern struct {
    /// Number of buffers in the array
    count: usize,
    /// Index of current buffer within the array
    idx: usize,
    /// Current offset within the current buffer
    off: usize,
    /// Array of buffers
    ///
    /// Don't use this directly, instead use the buf() helper
    _buf: [1]Buf,

    /// Initialize bufvec with a single buffer of given size
    pub fn init(size: usize) Bufvec {
        return .{
            .count = 1,
            .idx = 0,
            .off = 0,
            ._buf = .{.{
                .size = size,
                .flags = .{},
                .mem = null,
                .fd = -1,
                .pos = 0,
                .mem_size = 0,
            }},
        };
    }

    pub inline fn buf(self: *Bufvec) [*c]Buf {
        return @ptrCast(@alignCast(&self._buf));
    }

    comptime {
        std.debug.assert(@sizeOf(Bufvec) == if (is_x86_64_arch) 72 else 40);
        std.debug.assert(@alignOf(Bufvec) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Bufvec, "count") == 0);
        std.debug.assert(@offsetOf(Bufvec, "idx") == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Bufvec, "off") == if (is_x86_64_arch) 16 else 8);
        std.debug.assert(@offsetOf(Bufvec, "_buf") == if (is_x86_64_arch) 24 else 12);
    }
};

/// libfuse version a file system was compiled with.
pub const LibfuseVersion = extern struct {
    major: u32,
    minor: u32,
    hotfix: u32,
    padding: u32 = 0,

    comptime {
        std.debug.assert(@sizeOf(LibfuseVersion) == 16);
        std.debug.assert(@alignOf(LibfuseVersion) == 4);
        std.debug.assert(@offsetOf(LibfuseVersion, "major") == 0);
        std.debug.assert(@offsetOf(LibfuseVersion, "minor") == 4);
        std.debug.assert(@offsetOf(LibfuseVersion, "hotfix") == 8);
        std.debug.assert(@offsetOf(LibfuseVersion, "padding") == 12);
    }
};

/// Get total size of data in a fuse buffer vector
///
/// @return size of data
pub extern fn fuse_buf_size(
    /// Buffer vector
    bufv: *const Bufvec,
) usize;

/// Copy data from one buffer vector to another
///
/// @return actual number of bytes copied or -errno on error
pub extern fn fuse_buf_copy(
    /// Destination buffer vector
    dst: *Bufvec,
    /// Source buffer vector
    src: *Bufvec,
    /// Flags controlling the copy
    flags: Buf.CopyFlags,
) isize;

// ----- Data buffer End -----

// ----- Signal handling Begin -----

/// Exit session on HUP, TERM and INT signals and ignore PIPE signal
///
/// Stores session in a global variable. May only be called once per
/// process until fuse_remove_signal_handlers() is called.
///
/// Once either of the POSIX signals arrives, the signal handler calls
/// fuse_session_exit().
///
/// @return 0 on success, -1 on failure
///
/// See also:
/// fuse_remove_signal_handlers()
pub extern fn fuse_set_signal_handlers(
    /// The session to exit
    se: *Session,
) c_int;

/// Print a stack backtrace diagnostic on critical signals ()
///
/// Stores session in a global variable. May only be called once per
/// process until fuse_remove_signal_handlers() is called.
///
/// Once either of the POSIX signals arrives, the signal handler calls
/// fuse_session_exit().
///
/// @return 0 on success, -1 on failure
///
/// See also:
/// fuse_remove_signal_handlers()
pub extern fn fuse_set_fail_signal_handlers(
    /// The session to exit
    se: *Session,
) c_int;

/// Restore default signal handlers
///
/// Resets global session.  After this fuse_set_signal_handlers() may
/// be called again.
///
/// See also:
/// fuse_set_signal_handlers()
pub extern fn fuse_remove_signal_handlers(
    /// The same session as given in fuse_set_signal_handlers()
    se: *Session,
) void;

// ----- Signal handling End -----

// ----- Config operations Begin -----

/// Create and set default config for fuse_session_loop_mt and fuse_loop_mt.
///
/// @return anonymous config struct
pub extern fn fuse_loop_cfg_create() ?*LoopConfig;

/// Free the config data structure
pub extern fn fuse_loop_cfg_destroy(config: ?*LoopConfig) void;

/// fuse_loop_config setter to set the number of max idle threads.
pub extern fn fuse_loop_cfg_set_idle_threads(
    config: *LoopConfig,
    value: c_uint,
) void;

/// fuse_loop_config setter to set the number of max threads.
pub extern fn fuse_loop_cfg_set_max_threads(
    config: *LoopConfig,
    value: c_uint,
) void;

/// fuse_loop_config setter to enable the clone_fd feature
pub extern fn fuse_loop_cfg_set_clone_fd(
    config: *LoopConfig,
    value: c_uint,
) void;

/// Convert old config to more recernt fuse_loop_config2
pub extern fn fuse_loop_cfg_convert(
    /// Current config2 type
    config: *LoopConfig,
    /// Older config1 type (below FUSE API 312)
    v1_conf: *LoopConfigV1,
) void;

// ----- Config operations End -----

/// Set a feature flag in the want_ext field of fuse_conn_info.
///
/// @return true if the flag was set, false if the flag is not supported
pub extern fn fuse_set_feature_flag(
    /// Connection information
    conn: *ConnInfo,
    /// Feature flag to be set
    flag: u64,
) bool;

/// Unset a feature flag in the want_ext field of fuse_conn_info.
pub extern fn fuse_unset_feature_flag(
    /// Connection information
    conn: *ConnInfo,
    /// Feature flag to be unset
    flag: u64,
) void;

/// Get the value of a feature flag in the want_ext field of fuse_conn_info.
///
/// @return true if the flag is set, false otherwise
pub extern fn fuse_get_feature_flag(
    /// Connection information
    conn: *ConnInfo,
    /// Feature flag to be checked
    flag: u64,
) bool;

/// DO NOT USE: Not part of public API, for internal test use only.
/// The function signature or any use of it is not guaranteeed to
/// remain stable. And neither are results of what this function does.
pub extern fn fuse_convert_to_conn_want_ext(
    conn: *ConnInfo,
) c_int;

// ----- fuse_common.h End ------

// ----- fuse_log.h Begin ------

/// Log severity level
///
/// These levels correspond to syslog(2) log levels since they are widely used.
pub const LogLevel = enum(c_uint) {
    EMERG,
    ALERT,
    CRIT,
    ERR,
    WARNING,
    NOTICE,
    INFO,
    DEBUG,
};

/// Log message handler function.
///
/// This function must be thread-safe.  It may be called from any libfuse
/// function, including fuse_parse_cmdline() and other functions invoked before
/// a FUSE filesystem is created.
///
/// Install a custom log message handler function using fuse_set_log_func().
pub const LogFunc = *const fn (
    /// Log severity level
    level: LogLevel,
    /// sprintf-style format string including newline
    fmt: [*c]const u8,
    /// Format string arguments
    ap: if (is_x86_64_arch) [*c]std.lang.VaListX86_64 else std.lang.VaList,
) callconv(.c) void;

/// Install a custom log handler function.
///
/// Log messages are emitted by libfuse functions to report errors and debug
/// information.  Messages are printed to stderr by default but this can be
/// overridden by installing a custom log message handler function.
///
/// The log message handler function is global and affects all FUSE filesystems
/// created within this process.
pub extern fn fuse_set_log_func(
    /// a custom log message handler function
    /// or NULL to revert to the default
    func: ?LogFunc,
) void;

/// Emit a log message
pub extern fn fuse_log(
    /// Severity level (FUSE_LOG_ERR, FUSE_LOG_DEBUG, etc)
    level: LogLevel,
    /// sprintf-style format string including newline
    fmt: [*c]const u8,
    ...,
) void;

/// Switch default log handler from stderr to syslog
///
/// Passed options are according to 'man 3 openlog'
pub extern fn fuse_log_enable_syslog(
    ident: [*c]const u8,
    option: c_int,
    facility: c_int,
) void;

/// To be called at teardown to close syslog.
pub extern fn fuse_log_close_syslog() void;

// ----- fuse_log.h End ------

// ----- fuse_opt.h Begin ------

/// Option description
///
/// This structure describes a single option, and action associated
/// with it, in case it matches.
///
/// More than one such match may occur, in which case the action for
/// each match is executed.
///
/// There are three possible actions in case of a match:
///
/// i) An integer (int or unsigned) variable determined by 'offset' is
///    set to 'value'
///
/// ii) The processing function is called, with 'value' as the key
///
/// iii) An integer (any) or string (char *) variable determined by
///    'offset' is set to the value of an option parameter
///
/// 'offset' should normally be either set to
///
///  - 'offsetof(struct foo, member)'  actions i) and iii)
///
///  - -1                 action ii)
///
/// The 'offsetof()' macro is defined in the <stddef.h> header.
///
/// The template determines which options match, and also have an
/// effect on the action.  Normally the action is either i) or ii), but
/// if a format is present in the template, then action iii) is
/// performed.
///
/// The types of templates are:
///
/// 1) "-x", "-foo", "--foo", "--foo-bar", etc. These match only
///   themselves.  Invalid values are "--" and anything beginning
///   with "-o"
///
/// 2) "foo", "foo-bar", etc.  These match "-ofoo", "-ofoo-bar" or
///    the relevant option in a comma separated option list
///
/// 3) "bar=", "--foo=", etc.  These are variations of 1) and 2)
///    which have a parameter
///
/// 4) "bar=%s", "--foo=%lu", etc.  Same matching as above but perform
///    action iii).
///
/// 5) "-x ", etc.  Matches either "-xparam" or "-x param" as
///    two separate arguments
///
/// 6) "-x %s", etc.  Combination of 4) and 5)
///
/// If the format is "%s", memory is allocated for the string unlike with
/// scanf().  The previous value (if non-NULL) stored at the this location is
/// freed.
pub const Opt = extern struct {
    /// Matching template and optional parameter formatting */
    templ: [*c]const u8,
    /// Offset of variable within 'data' parameter of fuse_opt_parse()
    /// or -1
    offset: c_ulong,
    /// Value to set the variable to, or to be passed as 'key' to the
    /// processing function. Ignored if template has a format
    value: c_int,

    pub const Key = enum(c_int) {
        /// Key value passed to the processing function if an option did not
        /// match any template
        OPT = -1,
        /// Key value passed to the processing function for all non-options
        ///
        /// Non-options are the arguments beginning with a character other than
        /// '-' or all arguments after the special '--' option
        NONOPT = -2,
        /// Special key value for options to keep
        ///
        /// Argument is not passed to processing function, but behave as if the
        /// processing function returned 1
        KEEP = -3,
        /// Special key value for options to discard
        ///
        /// Argument is not passed to processing function, but behave as if the
        /// processing function returned zero
        DISCARD = -4,
        _,
    };

    /// Processing function
    ///
    /// This function is called if
    ///    - option did not match any 'struct fuse_opt'
    ///    - argument is a non-option
    ///    - option did match and offset was set to -1
    ///
    /// The 'arg' parameter will always contain the whole argument or
    /// option including the parameter if exists.  A two-argument option
    /// ("-x foo") is always converted to single argument option of the
    /// form "-xfoo" before this function is called.
    ///
    /// Options of the form '-ofoo' are passed to this function without the
    /// '-o' prefix.
    ///
    /// The return value of this function determines whether this argument
    /// is to be inserted into the output argument vector, or discarded.
    ///
    /// @return -1 on error, 0 if arg is to be discarded, 1 if arg should be kept
    pub const Proc = *const fn (
        /// Is the user data passed to the fuse_opt_parse() function
        data: ?*anyopaque,
        /// Is the whole argument or option
        arg: [*c]const u8,
        /// Determines why the processing function was called
        key: Opt.Key,
        /// The current output argument list
        outargs: *Args,
    ) callconv(.c) c_int;

    /// Key option. In case of a match, the processing function will be
    /// called with the specified key.
    pub fn KEY(templ: [*c]const u8, key: Key) Opt {
        return .{
            .templ = templ,
            .offset = std.math.maxInt(c_uint),
            .value = @backingInt(key),
        };
    }

    /// Last option. An array of 'struct fuse_opt' must end with a NULL
    /// template value
    pub const END: Opt = .{
        .templ = null,
        .offset = 0,
        .value = 0,
    };

    comptime {
        std.debug.assert(@sizeOf(Opt) == if (is_x86_64_arch) 24 else 12);
        std.debug.assert(@alignOf(Opt) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Opt, "templ") == 0);
        std.debug.assert(@offsetOf(Opt, "offset") == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Opt, "value") == if (is_x86_64_arch) 16 else 8);
    }
};

/// Argument list
pub const Args = extern struct {
    /// Argument count
    argc: c_int,
    /// Argument vector.  NULL terminated
    argv: [*c][*c]u8,
    /// Is 'argv' allocated?
    allocated: c_int,

    /// Initializer for 'struct fuse_args'
    pub fn INIT(argc: c_int, argv: [*c][*c]u8) Args {
        return .{
            .argc = argc,
            .argv = argv,
            .allocated = 0,
        };
    }

    comptime {
        std.debug.assert(@sizeOf(Args) == if (is_x86_64_arch) 24 else 12);
        std.debug.assert(@alignOf(Args) == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Args, "argc") == 0);
        std.debug.assert(@offsetOf(Args, "argv") == if (is_x86_64_arch) 8 else 4);
        std.debug.assert(@offsetOf(Args, "allocated") == if (is_x86_64_arch) 16 else 8);
    }
};

/// Option parsing function
///
/// If 'args' was returned from a previous call to fuse_opt_parse() or
/// it was constructed from
///
/// A NULL 'args' is equivalent to an empty argument vector
///
/// A NULL 'opts' is equivalent to an 'opts' array containing a single
/// end marker
///
/// A NULL 'proc' is equivalent to a processing function always
/// returning '1'
///
/// @return -1 on error, 0 on success
pub extern fn fuse_opt_parse(
    /// The input and output argument list
    args: ?*Args,
    /// The user data
    data: ?*anyopaque,
    /// The option description array
    opts: [*c]const Opt,
    /// The processing function
    proc: ?Opt.Proc,
) c_int;

/// Add an option to a comma separated option list
///
/// @return -1 on allocation error, 0 on success
pub extern fn fuse_opt_add_opt(
    /// A pointer to an option list, may point to a NULL value
    opts: ?*[*c]u8,
    /// The option to add
    opt: [*c]const u8,
) c_int;

/// Add an option, escaping commas, to a comma separated option list
///
/// @return -1 on allocation error, 0 on success
pub extern fn fuse_opt_add_opt_escaped(
    /// A pointer to an option list, may point to a NULL value
    opts: ?*[*c]u8,
    /// The option to add
    opt: [*c]const u8,
) c_int;

/// Add an argument to a NULL terminated argument vector
///
/// @return -1 on allocation error, 0 on success
pub extern fn fuse_opt_add_arg(
    /// The structure containing the current argument list
    args: *Args,
    /// The new argument to add
    arg: [*c]const u8,
) c_int;

/// Add an argument at the specified position in a NULL terminated
/// argument vector
///
/// Adds the argument to the N-th position.  This is useful for adding
/// options at the beginning of the array which must not come after the
/// special '--' option.
///
/// @return -1 on allocation error, 0 on success
pub extern fn fuse_opt_insert_arg(
    /// The structure containing the current argument list
    args: *Args,
    /// The position at which to add the argument
    pos: c_int,
    /// The new argument to add
    arg: [*c]const u8,
) c_int;

/// Free the contents of argument list
///
/// The structure itself is not freed
pub extern fn fuse_opt_free_args(
    /// The structure containing the argument list
    args: *Args,
) void;

/// Check if an option matches
///
/// @return 1 if a match is found, 0 if not
pub extern fn fuse_opt_match(
    /// The option description array
    opts: [*c]const Opt,
    /// The option to match
    opt: [*c]const u8,
) c_int;

// ----- fuse_opt.h End ------

test "all" {
    std.testing.refAllDecls(@This());
}
