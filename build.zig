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
    run_exe_unit_tests.has_side_effects = true;
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
        options: ?*std.Build.Step.Options = null,
    };

    const test_sound_timer = testProg(b, TestAppStepOptions{
        .main_source = b.path("test/sound_timer/main.zig"),
        .step_name = "test-sound-timer",
        .step_desc = "Sound timer test",
        .chip8 = _exe,
        .target = target,
        .optimize = optimize,
    });
    _ = test_sound_timer;

    const test_display = testProg(b, TestAppStepOptions{
        .main_source = b.path("test/display/main.zig"),
        .step_name = "test-display",
        .step_desc = "Display test",
        .chip8 = _exe,
        .target = target,
        .optimize = optimize,
    });
    _ = test_display;

    // TODO: Add option to also control test time
    const test_number = b.option(usize, "test-number", "Run only specific test from test suite") orelse 0;
    const test_time = b.option(usize, "test-time", "Run each test suite for this amount of time") orelse 3;
    const test_suite_opts = b.addOptions();
    test_suite_opts.addOption(usize, "test_number", test_number);
    test_suite_opts.addOption(usize, "test_time", test_time);

    const test_suite = testProg(b, TestAppStepOptions{
        .main_source = b.path("test/test-suite/main.zig"),
        .step_name = "test-suite",
        .step_desc = "Run Timendius' chip8 test suite",
        .chip8 = _exe,
        .target = target,
        .optimize = optimize,
        .options = test_suite_opts,
    });
    _ = test_suite;
}

fn testProg(b: *std.Build, opt: anytype) *std.Build.Step.Run {
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
    if (opt.options) |o| {
        test_prog.root_module.addOptions("options", o);
    }
    const test_prog_runner = b.addRunArtifact(test_prog);
    test_prog_runner.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        test_prog_runner.addArgs(args);
    }

    const out_step = b.step(opt.step_name, opt.step_desc);
    out_step.dependOn(&test_prog_runner.step);

    return test_prog_runner;
}
