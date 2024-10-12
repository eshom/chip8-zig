const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "chip8-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    exe.addIncludePath(b.path("vendor/raylib/src"));
    exe.addLibraryPath(b.path("vendor/raylib/src"));
    exe.addObjectFile(b.path("vendor/raylib/src/libraylib.a"));
    b.installArtifact(exe);

    const check_exe = b.addExecutable(.{
        .name = "chip8-zig-check",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const check = b.step("check", "Check build errors for LSP");
    check.dependOn(&check_exe.step);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .filter = b.option([]const u8, "test-filter", "String to filter tests by"),
    });

    exe_unit_tests.addIncludePath(b.path("vendor/raylib/src"));
    exe_unit_tests.addLibraryPath(b.path("vendor/raylib/src"));
    exe_unit_tests.addObjectFile(b.path("vendor/raylib/src/libraylib.a"));
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
