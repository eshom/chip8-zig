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

    // Module for testing apps
    const _exe = b.createModule(.{
        .root_source_file = b.path("src/chip8.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    _exe.addIncludePath(b.path("vendor/raylib/src"));
    _exe.addLibraryPath(b.path("vendor/raylib/src"));
    _exe.addObjectFile(b.path("vendor/raylib/src/libraylib.a"));

    // Testing apps
    const test_sound_timer = b.addExecutable(.{
        .name = "chip8-zig",
        .root_source_file = b.path("test/sound_timer/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    test_sound_timer.addIncludePath(b.path("vendor/raylib/src"));
    test_sound_timer.addLibraryPath(b.path("vendor/raylib/src"));
    test_sound_timer.addObjectFile(b.path("vendor/raylib/src/libraylib.a"));
    test_sound_timer.root_module.addImport("chip8", _exe);
    const test_sound_timer_runner = b.addRunArtifact(test_sound_timer);
    test_sound_timer_runner.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        test_sound_timer_runner.addArgs(args);
    }
    const test_sound_timer_runner_step = b.step("test-sound-timer", "Sound timer test app");
    test_sound_timer_runner_step.dependOn(&test_sound_timer_runner.step);
}
