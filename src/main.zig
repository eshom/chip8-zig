const std = @import("std");
const memory = @import("memory.zig");
const font = @import("font.zig");
const display = @import("display.zig");
const timing = @import("timing.zig");
const rl = @import("raylib.zig");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;

const Cycle = timing.Cycle;

pub const std_options = .{
    .log_level = .debug,
};

const RuntimeOptions = struct {
    cpu_delay_s: f64 = 0.001,
    timings_print_cycle: usize = 700,
};

pub fn main() !void {
    @memset(&memory.ram, 0);
    var _fba = heap.FixedBufferAllocator.init(memory.ram[memory.PROGRAM_START..]);
    const fba = _fba.allocator();
    _ = fba; // autofix

    font.setFont(&memory.ram, &font.font_chars);

    memory.debugDumpMemory(&memory.ram, 16);

    try mainLoop(.{});
}

pub fn mainLoop(opt: RuntimeOptions) !void {
    rl.setLogLevel(.log_error);
    display.initWindow("CHIP-8", .{});
    defer display.closeWindow();

    const start_time = time.microTimestamp();
    var cycles = Cycle{ .start_time_us = time.microTimestamp() };
    while (!display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.start_time_us = time.microTimestamp();
    }) {
        display.beginDrawing();
        display.endDrawing();

        timing.waitTime(opt.cpu_delay_s);

        if (cycles.total % opt.timings_print_cycle == 0) {
            log.debug("run time us: {d}, total cycle: {d}, last cycle time us: {d}", .{
                time.microTimestamp() - start_time,
                cycles.total,
                time.microTimestamp() - cycles.start_time_us,
            });
        }
    }
}
