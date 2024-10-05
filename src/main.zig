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
const math = std.math;

const Allocator = std.mem.Allocator;

const Cycle = timing.Cycle;
const DelayTimer = timing.DelayTimer;
const SoundTimer = timing.SoundTimer;

pub const std_options = .{
    .log_level = .debug,
};

// Goal is 700 instructions per second
const RuntimeOptions = struct {
    cpu_delay_s: f64 = 0.0012,
    debug_timings_print_cycle: usize = 100,
    scale: u16 = 16,
};

pub fn main() !void {
    rl.setLogLevel(.log_error);

    @memset(&memory.ram, 0);
    var _fba = heap.FixedBufferAllocator.init(memory.ram[memory.PROGRAM_START..]);
    const fba = _fba.allocator();

    font.setFont(&memory.ram, &font.font_chars);

    // Debug memory dump
    // memory.debugDumpMemory(&memory.ram, 16);

    try mainLoop(fba, .{});
}

pub fn mainLoop(ally: Allocator, opt: RuntimeOptions) !void {
    _ = ally; // autofix

    var delay_timer = DelayTimer{};
    var sound_timer = SoundTimer{};

    timing.initAudioDevice();
    const beep = timing.loadSound(sound_timer.sound);

    display.initWindow("CHIP-8", .{ .scale = opt.scale });
    defer display.closeWindow();

    const debug_start_time = time.microTimestamp();
    var debug_curr_time = debug_start_time;
    // var debug_last_print_time_us = debug_curr_time;

    var cycles = Cycle{
        .curr_time_s = timing.getTime(),
        .prev_time_s = undefined,
        .delta_time_s = undefined,
    };
    cycles.prev_time_s = cycles.curr_time_s;
    cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;

    // temp stuff to have on screen
    display.screen[16][16] = 1;
    display.screen[32][16] = 1;
    display.screen[48][16] = 1;
    display.screen[32][24] = 1;
    display.screen[32][8] = 1;

    while (!display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;
        cycles.prev_time_s = cycles.curr_time_s;
        cycles.curr_time_s = timing.getTime();
        cycles.time_since_draw_s += cycles.delta_time_s;
        if (delay_timer.timer != 0) delay_timer.last_tick_s += cycles.delta_time_s;
        if (sound_timer.timer != 0) sound_timer.last_tick_s += cycles.delta_time_s;
        debug_curr_time = time.microTimestamp();
    }) {
        input.pollInputEvents();

        if (delay_timer.timer != 0 and delay_timer.last_tick_s > delay_timer.rate) {
            delay_timer.timer -= 1;
            delay_timer.last_tick_s = 0;
        }

        if (sound_timer.timer != 0 and sound_timer.last_tick_s > sound_timer.rate) {
            sound_timer.timer -= 1;
            if (sound_timer.timer == 0) {
                timing.playSound(beep);
            }
            sound_timer.last_tick_s = 0;
        }

        if (cycles.time_since_draw_s > 1 / cycles.target_fps) {
            // Drawing start
            display.beginDrawing();

            display.clearBackground(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
            display.drawScreen(&display.screen, opt.scale, rl.raylib.RAYWHITE);

            if (sound_timer.timer == 0) {
                sound_timer.timer = 240;
            }

            display.endDrawing();
            display.swapScreenBuffer();
            cycles.last_draw_delta_s = cycles.time_since_draw_s;
            cycles.time_since_draw_s = 0;
            // Drawing end
        }

        timing.waitTime(opt.cpu_delay_s);

        // Debug stuff
        // if (cycles.total % opt.debug_timings_print_cycle == 0) {
        //     log.debug("run time us: {d}, total cycle: {d}, last cycle time us: {d}, last print time us: {d}, time since last update: {d:.4}, last draw delta: {d:.4}", .{
        //         time.microTimestamp() - debug_start_time,
        //         cycles.total,
        //         time.microTimestamp() - debug_curr_time,
        //         time.microTimestamp() - debug_last_print_time_us,
        //         cycles.time_since_draw_s,
        //         cycles.last_draw_delta_s,
        //     });
        //     debug_last_print_time_us = time.microTimestamp();
        // }

        // log.debug("cycle: {d}, time since last tick: {d:.4}, sound timer: {d}", .{ cycles.total, sound_timer.last_tick_s, sound_timer.timer });
        // log.debug("cycle: {d}, time since last tick: {d:.4}, delay timer: {d}", .{ cycles.total, delay_timer.last_tick_s, delay_timer.timer });
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
