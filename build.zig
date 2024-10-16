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
    check.dependOn(&exe_unit_tests.step);

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
    const TestAppStepOptions = struct {
        main_source: std.Build.LazyPath,
        step_name: []const u8,
        step_desc: []const u8,
        chip8: *std.Build.Module,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
    };

    const test_sound_timer_step = testProg(b, TestAppStepOptions{
        .main_source = b.path("test/sound_timer/main.zig"),
        .step_name = "test-sound-timer",
        .step_desc = "Sound timer test app",
        .chip8 = _exe,
        .target = target,
        .optimize = optimize,
    });

    const test_display_step = testProg(b, TestAppStepOptions{
        .main_source = b.path("test/display/main.zig"),
        .step_name = "test-display",
        .step_desc = "Display test app",
        .chip8 = _exe,
        .target = target,
        .optimize = optimize,
    });

    const test_all = b.step("test-all", "Run all test apps one by one");
    test_all.dependOn(test_sound_timer_step);
    test_all.dependOn(test_display_step);
}

fn testProg(b: *std.Build, opt: anytype) *std.Build.Step {
    const test_prog = b.addExecutable(.{
        .name = "chip8-zig",
        .root_source_file = opt.main_source,
        .target = opt.target,
        .optimize = opt.optimize,
        .link_libc = true,
    });
    test_prog.addIncludePath(b.path("vendor/raylib/src"));
    test_prog.addLibraryPath(b.path("vendor/raylib/src"));
    test_prog.addObjectFile(b.path("vendor/raylib/src/libraylib.a"));
    test_prog.root_module.addImport("chip8", opt.chip8);
    const test_prog_runner = b.addRunArtifact(test_prog);
    test_prog_runner.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        test_prog_runner.addArgs(args);
    }

    const out_step = b.step(opt.step_name, opt.step_desc);
    out_step.dependOn(&test_prog_runner.step);

    return out_step;
}
