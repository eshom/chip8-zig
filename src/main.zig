const std = @import("std");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;
const math = std.math;
const memory = @import("memory.zig");
const font = @import("font.zig");
const display = @import("display.zig");
const timing = @import("timing.zig");
const rl = @import("raylib.zig");
const input = @import("input.zig");
const inst = @import("inst.zig");

const Allocator = std.mem.Allocator;
const Cycle = timing.Cycle;
const DelayTimer = timing.DelayTimer;
const SoundTimer = timing.SoundTimer;
const ProgramCounter = inst.ProgramCounter;
const Memory = memory.Memory;
const Reg = memory.Reg;
const Screen = display.Screen;
const Config = @import("Config.zig");

pub const std_options = .{
    .log_level = .debug,
};

pub const Devices = struct {
    pc: ProgramCounter = .{},
    ram: Memory = .{0} ** memory.TOTAL_MEM,
    stack: memory.Stack(Config.stack_size) = .{},
    reg: Reg = .{},
    screen: Screen = .{.{0} ** display.HEIGHT} ** display.WIDTH,
    delay_timer: DelayTimer = .{},
    sound_timer: SoundTimer = .{},
};

pub fn main() !void {
    rl.setLogLevel(.log_error);
    var dev: Devices = .{};

    var _fba = heap.FixedBufferAllocator.init(dev.ram[memory.PROGRAM_START..]);
    const fba = _fba.allocator();

    font.setFont(&dev.ram, &font.font_chars);

    try mainLoop(fba, &dev);
}

pub fn mainLoop(ally: Allocator, dev: *Devices) !void {
    _ = ally; // autofix

    timing.initAudioDevice();
    const beep = timing.loadSound(dev.sound_timer.sound);

    display.initWindow("CHIP-8", .{ .scale = Config.scale });
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
    dev.screen[16][16] = 1;
    dev.screen[32][16] = 1;
    dev.screen[48][16] = 1;
    dev.screen[32][24] = 1;
    dev.screen[32][8] = 1;
    // temporary timer
    dev.sound_timer.timer = 240;

    while (!display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;
        cycles.prev_time_s = cycles.curr_time_s;
        cycles.curr_time_s = timing.getTime();
        cycles.time_since_draw_s += cycles.delta_time_s;
        if (dev.delay_timer.timer != 0) dev.delay_timer.last_tick_s += cycles.delta_time_s;
        if (dev.sound_timer.timer != 0) dev.sound_timer.last_tick_s += cycles.delta_time_s;
        debug_curr_time = time.microTimestamp();
    }) {
        input.pollInputEvents();

        if (dev.delay_timer.timer != 0 and dev.delay_timer.last_tick_s > dev.delay_timer.rate) {
            dev.delay_timer.timer -= 1;
            dev.delay_timer.last_tick_s = 0;
        }

        if (dev.sound_timer.timer != 0 and dev.sound_timer.last_tick_s > dev.sound_timer.rate) {
            dev.sound_timer.timer -= 1;
            if (dev.sound_timer.timer == 0) {
                timing.playSound(beep);
            }
            dev.sound_timer.last_tick_s = 0;
        }

        if (cycles.time_since_draw_s > 1 / cycles.target_fps) {
            // Drawing start
            display.beginDrawing();

            display.clearBackground(Config.bg_color);
            display.drawScreen(&dev.screen, Config.scale, rl.rl.RAYWHITE);

            // temporary check
            if (dev.sound_timer.timer == 0) {
                dev.sound_timer.timer = 240;
                // clearScreen when timer goes out
                (inst.Inst{ .nb3 = 0xe }).execute(dev);
            }

            display.endDrawing();
            display.swapScreenBuffer();
            cycles.last_draw_delta_s = cycles.time_since_draw_s;
            cycles.time_since_draw_s = 0;
            // Drawing end
        }

        timing.waitTime(Config.cpu_delay_s);

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
    _ = @import("inst.zig");
    _ = @import("Config.zig");
}
