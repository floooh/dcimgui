// NOTE: unfortunately switching to the 'prefix-less' functions in
// zimgui.h isn't that easy because some Dear ImGui functions collide
// with Win32 function (Set/GetCursorPos and Set/GetWindowPos).
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opt_dynamic_linkage = b.option(bool, "dynamic_linkage", "Builds cimgui_clib artifact with dynamic linkage.") orelse false;
    const opt_with_docking = b.option(bool, "with_docking", "Uses the docking branch of (c)ImGui") orelse false;

    var cflags = try std.BoundedArray([]const u8, 64).init(0);
    if (target.result.cpu.arch.isWasm()) {
        // on WASM, switch off UBSAN (zig-cc enables this by default in debug mode)
        // but it requires linking with an ubsan runtime)
        try cflags.append("-fno-sanitize=undefined");
    }

    // Choose source paths based on docking option
    const src_dir = if (opt_with_docking) "src-docking" else "src";
    const cimgui_cpp_files = &.{
        try std.fmt.allocPrint(b.allocator, "{s}/cimgui.cpp", .{src_dir}),
        try std.fmt.allocPrint(b.allocator, "{s}/imgui_demo.cpp", .{src_dir}),
        try std.fmt.allocPrint(b.allocator, "{s}/imgui_draw.cpp", .{src_dir}),
        try std.fmt.allocPrint(b.allocator, "{s}/imgui_tables.cpp", .{src_dir}),
        try std.fmt.allocPrint(b.allocator, "{s}/imgui_widgets.cpp", .{src_dir}),
        try std.fmt.allocPrint(b.allocator, "{s}/imgui.cpp", .{src_dir}),
    };
    const cimgui_h_path = b.path(try std.fmt.allocPrint(b.allocator, "{s}/cimgui.h", .{src_dir}));

    // build cimgui_clib as a module
    const mod_cimgui_clib = b.addModule("mod_cimgui_clib", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod_cimgui_clib.addCSourceFiles(.{
        .files = cimgui_cpp_files,
        .flags = cflags.slice(),
    });

    // make cimgui available as artifact, this allows to inject
    // the Emscripten sysroot include path in another build.zig
    const lib_cimgui = b.addLibrary(.{
        .name = "cimgui_clib",
        .linkage = if (opt_dynamic_linkage) .dynamic else .static,
        .root_module = mod_cimgui_clib,
    });
    b.installArtifact(lib_cimgui);

    // translate-c the cimgui.h file
    // NOTE: running this step with the host target is intended to avoid
    // any Emscripten header search path shenanigans
    const translateC = b.addTranslateC(.{
        .root_source_file = cimgui_h_path,
        .target = b.graph.host,
        .optimize = optimize,
    });

    // build cimgui as module
    const mod_cimgui = b.addModule("cimgui", .{
        .root_source_file = translateC.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod_cimgui.linkLibrary(lib_cimgui);

    // Only create an DearImGUI internal API Zig module if docking is enabled
    if (opt_with_docking) {
        const cimgui_internal_h_path = b.path("src-docking/cimgui_internal.h");
        const translateCInternal = b.addTranslateC(.{
            .root_source_file = cimgui_internal_h_path,
            .target = b.graph.host,
            .optimize = optimize,
        });
        const mod_cimgui_internal = b.addModule("cimgui_internal", .{
            .root_source_file = translateCInternal.getOutput(),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });
        // Make the internal module depend on the main one:
        mod_cimgui_internal.addImport("cimgui", mod_cimgui);
    }
}
