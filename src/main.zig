const std = @import("std");
const memory = @import("memory.zig");
const font = @import("font.zig");
const display = @import("display.zig");
const timing = @import("timing.zig");
const rl = @import("raylib.zig");
const input = @import("input.zig");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;

const Cycle = timing.Cycle;

pub const std_options = .{
    .log_level = .debug,
};

// Goal is 700 instructions per second
const RuntimeOptions = struct {
    cpu_delay_s: f64 = 0.0012,
    debug_timings_print_cycle: usize = 100,
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

    const debug_start_time = time.microTimestamp();
    var debug_curr_time = debug_start_time;
    var debug_last_print_time_us = debug_curr_time;

    var cycles = Cycle{
        .curr_time_s = timing.getTime(),
        .prev_time_s = undefined,
        .delta_time_s = undefined,
    };
    cycles.prev_time_s = cycles.curr_time_s;
    cycles.delta_time_s = cycles.curr_time_s - cycles.delta_time_s;

    while (!display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;
        cycles.prev_time_s = cycles.curr_time_s;
        cycles.curr_time_s = timing.getTime();
        cycles.time_since_draw_s += cycles.delta_time_s;
        debug_curr_time = time.microTimestamp();
    }) {
        input.pollInputEvents();

        if (cycles.time_since_draw_s > 1 / cycles.target_fps) {
            // Drawing start
            display.beginDrawing();
            if (cycles.total % 700 >= 0 and cycles.total % 700 < 350) {
                display.clearBackground(.{ .r = 0, .g = 100, .b = 0, .a = 255 });
            } else {
                display.clearBackground(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
            }
            display.endDrawing();
            display.swapScreenBuffer();
            cycles.last_draw_delta_s = cycles.time_since_draw_s;
            cycles.time_since_draw_s = 0;
            // Drawing end
        }

        timing.waitTime(opt.cpu_delay_s);

        if (cycles.total % opt.debug_timings_print_cycle == 0) {
            log.debug("run time us: {d}, total cycle: {d}, last cycle time us: {d}, last print time us: {d}, time since last update: {d:.4}, last draw delta: {d:.4}", .{
                time.microTimestamp() - debug_start_time,
                cycles.total,
                time.microTimestamp() - debug_curr_time,
                time.microTimestamp() - debug_last_print_time_us,
                cycles.time_since_draw_s,
                cycles.last_draw_delta_s,
            });
            debug_last_print_time_us = time.microTimestamp();
        }
    }
}

test {
    _ = @import("memory.zig");
    _ = @import("font.zig");
    _ = @import("display.zig");
    _ = @import("timing.zig");
    _ = @import("raylib.zig");
    _ = @import("input.zig");
}
