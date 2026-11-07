const std = @import("std");

const libfuse_version_string: [:0]const u8 = @import("build.zig.zon").libfuse_version;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const defines = b.addOptions();

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Link mode to use (default: static)") orelse
        .static;

    const enable_usdt = b.option(bool, "enable-usdt", "Enable user statically defined tracepoints for extra observability") orelse
        false;
    // TODO: Add option enable-io-uring; this will pull in liburing and numa dependencies
    const enable_io_uring = false;

    const enable_custom_io = b.option(bool, "enable-custom-io", "Enable fuse_session_custom_io(), which serves the protocol over a caller-provided fd instead of /dev/fuse. The peer might not be a kernel and can forge requests that libfuse parses without bounds checks, crashing or corrupting the filesystem process - see doc/README.custom-io") orelse
        false;
    if (enable_custom_io) {
        std.log.warn("{s} {s} {s} {s}", .{
            "enable-custom-io lets a peer that might not be a kernel send",
            "requests that libfuse parses without bounds checks, so a",
            "forged request can crash or corrupt the filesystem process -",
            "see doc/README.custom-io.",
        });
    }

    if (target.result.os.tag.isDarwin()) {
        @panic(
            \\libfuse does not support OS-X.
            \\Take a look at http://osxfuse.github.io/ or the more recent
            \\https://www.fuse-t.org/ instead
        );
    } else if (target.result.os.tag == .windows) {
        @panic(
            \\libfuse does not support Windows.
            \\Take a look at http://www.secfs.net/winfsp/ instead
        );
    }

    const mod = b.addModule("root", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "defines", .module = defines.createModule() },
        },
    });

    const lib = b.addLibrary(.{
        .name = "fuse3",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = linkage,
        .version = try .parse(libfuse_version_string),
    });
    const install_lib = b.addInstallArtifact(lib, .{});
    mod.linkLibrary(lib);

    if (linkage == .dynamic) {
        const ln = b.addSystemCommand(&.{
            "ln", "-sf", "libfuse3.so.3.18.3", "libfuse3.so.4",
        });
        ln.setCwd(b.graph.path(.install_lib, ""));
        ln.step.dependOn(&install_lib.step);
        b.getInstallStep().dependOn(&ln.step);
    } else {
        b.getInstallStep().dependOn(&install_lib.step);
    }

    const upstream_dep = b.dependency("upstream", .{});

    const versioned_symbols: bool = linkage == .dynamic and target.result.abi.isGnu();
    if (versioned_symbols) {
        std.log.info("Enabling versioned libc symbols", .{});
        lib.setVersionScript(upstream_dep.path("lib/fuse_versionscript"));
    }
    defines.addOption(bool, "LIBFUSE_BUILT_WITH_VERSIONED_SYMBOLS", versioned_symbols);

    {
        lib.root_module.addCMacro("FUSE_USE_VERSION", "317");
        lib.root_module.addCMacro("FUSERMOUNT_DIR", "");

        lib.root_module.addCMacro(
            "PACKAGE_VERSION",
            b.fmt("{q}", .{libfuse_version_string}),
        );

        lib.root_module.addCMacro("HAVE_FORK", "");
        lib.root_module.addCMacro("HAVE_FSTATAT", "");
        lib.root_module.addCMacro("HAVE_OPENAT", "");
        lib.root_module.addCMacro("HAVE_READLINKAT", "");
        lib.root_module.addCMacro("HAVE_PIPE2", "");
        lib.root_module.addCMacro("HAVE_SPLICE", "");
        lib.root_module.addCMacro("HAVE_VMSPLICE", "");
        lib.root_module.addCMacro("HAVE_POSIX_FALLOCATE", "");
        lib.root_module.addCMacro("HAVE_FDATASYNC", "");
        lib.root_module.addCMacro("HAVE_UTIMENSAT", "");
        lib.root_module.addCMacro("HAVE_COPY_FILE_RANGE", "");
        lib.root_module.addCMacro("HAVE_FALLOCATE", "");
        // lib.root_module.addCMacro("HAVE_FSPACECTL", "");

        lib.root_module.addCMacro("HAVE_PTHREAD_SETNAME_NP", "");
        lib.root_module.addCMacro("HAVE_CLOSE_RANGE", "");
        lib.root_module.addCMacro("HAVE_LISTMOUNT", "");

        lib.root_module.addCMacro("HAVE_XATTR_H", "");
        lib.root_module.addCMacro("HAVE_LIMITS_H", "");

        lib.root_module.addCMacro("HAVE_SETXATTR", "");
        lib.root_module.addCMacro("HAVE_ICONV", "");
        if (target.result.abi.isGnu()) {
            lib.root_module.addCMacro("HAVE_BACKTRACE", "");
        }
        lib.root_module.addCMacro("HAVE_STATX", "");

        lib.root_module.addCMacro("HAVE_STRUCT_STAT_ST_ATIM", "");
        // lib.root_module.addCMacro("HAVE_STRUCT_STAT_ST_ATIMESPEC", "");

        if (enable_usdt) {
            lib.root_module.addCMacro("USDT_ENABLED", "");
        }
        if (enable_io_uring) {
            lib.root_module.addCMacro("HAVE_URING", "");
        }
        if (enable_custom_io) {
            lib.root_module.addCMacro("HAVE_CUSTOM_IO", "");
        }
        if (versioned_symbols) {
            lib.root_module.addCMacro("LIBFUSE_BUILT_WITH_VERSIONED_SYMBOLS", "1");
            std.log.info("Compiler supports symver attribute", .{});
            // lib.root_module.addCMacro("HAVE_SYMVER_ATTRIBUTE", "1");
        }
    }

    const config_header = b.addConfigHeader(.{
        .include_path = "libfuse_config.h",
    }, .{
        .FUSE_MAJOR_VERSION = @as(i64, @intCast(lib.version.?.major)),
        .FUSE_MINOR_VERSION = @as(i64, @intCast(lib.version.?.minor)),
        .FUSE_HOTFIX_VERSION = @as(i64, @intCast(lib.version.?.patch)),
    });
    if (versioned_symbols) {
        config_header.addIdent("LIBFUSE_BUILT_WITH_VERSIONED_SYMBOLS", "1");
    }
    if (lib.version.?.pre) |pre| {
        config_header.addIdent("FUSE_RC_VERSION", pre);
    } else {
        config_header.addIdent("FUSE_RC_VERSION", "");
    }
    lib.installHeader(config_header.getOutputFile(), "fuse3/libfuse_config.h");
    lib.root_module.addConfigHeader(config_header);

    const file = b.addWriteFiles().addCopyFile(config_header.getOutputFile(), "fuse_config.h");

    lib.root_module.addIncludePath(upstream_dep.path("include"));
    lib.root_module.addIncludePath(upstream_dep.path("lib"));
    lib.root_module.addIncludePath(file.dirname());
    lib.root_module.addIncludePath(config_header.getOutputDir());
    for ([_][]const u8{
        "include/fuse.h",
        "include/fuse_common.h",
        "include/fuse_lowlevel.h",
        "include/fuse_opt.h",
        "include/cuse_lowlevel.h",
        "include/fuse_log.h",
    }) |header_name| {
        lib.installHeader(
            upstream_dep.path(header_name),
            b.fmt("fuse3/{s}", .{header_name["include/".len..]}),
        );
    }

    const c_sources_and_mount =
        if (target.result.os.tag == .linux)
            c_sources ++ [_][]const u8{"lib/mount.c"}
        else
            c_sources ++ [_][]const u8{"lib/mount_bsd.c"};
    const c_sources_and_iconv =
        c_sources_and_mount ++ [_][]const u8{"lib/modules/iconv.c"};
    const c_sources_complete =
        if (enable_io_uring)
            c_sources_and_iconv ++ [_][]const u8{"lib/fuse_uring.c"}
        else
            c_sources_and_iconv;
    for (c_sources_complete) |source_name| {
        lib.root_module.addCSourceFile(.{
            .language = .c,
            .file = upstream_dep.path(source_name),
            .flags = &.{
                "-std=gnu11",
                "-D_REENTRANT",
                "-DHAVE_LIBFUSE_PRIVATE_CONFIG_H",
                "-D_FILE_OFFSET_BITS=64",
                "-Wno-sign-compare",
                "-Wstrict-prototypes",
                "-Wmissing-declarations",
                "-Wwrite-strings",
                "-fno-strict-aliasing",
            },
        });
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}

const c_sources = [_][]const u8{
    "lib/fuse.c",
    "lib/fuse_loop.c",
    "lib/fuse_loop_mt.c",
    "lib/fuse_lowlevel.c",
    "lib/fuse_opt.c",
    "lib/fuse_signals.c",
    "lib/buffer.c",
    "lib/cuse_lowlevel.c",
    "lib/helper.c",
    "lib/modules/subdir.c",
    "lib/mount_util.c",
    "lib/fuse_log.c",
    "lib/compat.c",
    "lib/util.c",
};
