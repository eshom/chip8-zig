const std = @import("std");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;
const math = std.math;

const c8 = @import("chip8.zig");

const Allocator = std.mem.Allocator;
const Cycle = c8.timing.Cycle;
const DelayTimer = c8.timing.DelayTimer;
const SoundTimer = c8.timing.SoundTimer;
const ProgramCounter = c8.inst.ProgramCounter;
const Memory = c8.memory.Memory;
const Reg = c8.memory.Reg;
const Screen = c8.display.Screen;
const Devices = c8.Devices;
const Config = c8.Config;

pub const std_options = .{
    .log_level = .info,
};

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: Devices = Devices.init();
    try dev.loadRom(c8.Config.rom_file);
    try mainLoop(&dev);
}

pub fn mainLoop(dev: *Devices) !void {
    c8.display.initWindow("CHIP-8", .{ .scale = Config.scale });
    defer c8.display.closeWindow();

    var cycles = Cycle{
        .curr_time_s = c8.timing.getTime(),
        .prev_time_s = undefined,
        .delta_time_s = undefined,
    };
    cycles.prev_time_s = cycles.curr_time_s;
    cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;

    while (!c8.display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;
        cycles.prev_time_s = cycles.curr_time_s;
        cycles.curr_time_s = c8.timing.getTime();
        cycles.time_since_draw_s += cycles.delta_time_s;
        if (dev.delay_timer.timer != 0) dev.delay_timer.last_tick_s += cycles.delta_time_s;
        if (dev.sound_timer.timer != 0) dev.sound_timer.last_tick_s += cycles.delta_time_s;
    }) {
        c8.input.pollInputEvents();

        // Fetch instruction and execute
        const inst = try dev.pc.fetch(&dev.ram);
        inst.decode(dev);

        // Drawing happens here at 60 FPS (by default)
        if (cycles.time_since_draw_s > 1 / cycles.target_fps) {
            c8.display.beginDrawing();
            c8.display.clearBackground(Config.bg_color);
            c8.display.drawScreen(&dev.screen, Config.scale, c8.raylib.rl.RAYWHITE);
            c8.display.endDrawing();
            c8.display.swapScreenBuffer();
            cycles.last_draw_delta_s = cycles.time_since_draw_s;
            cycles.time_since_draw_s = 0;
        }

        c8.timing.waitTime(Config.cpu_delay_s);
    }
}

test {
    _ = @import("chip8.zig");
}
