const std = @import("std");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;
const math = std.math;

const c8 = @import("chip8");

const Allocator = std.mem.Allocator;
const Cycle = c8.timing.Cycle;
const DelayTimer = c8.timing.DelayTimer;
const SoundTimer = c8.timing.SoundTimer;
const ProgramCounter = c8.inst.ProgramCounter;
const Memory = c8.memory.Memory;
const Reg = c8.memory.Reg;
const Screen = c8.display.Screen;
const Devices = c8.Devices;
const Config = @import("Config.zig");

pub const std_options = .{
    .log_level = .info,
};

fn exitTime(t: i64) void {
    const timer = struct {
        var start: i64 = -1;
    };

    if (timer.start == -1) {
        timer.start = time.timestamp();
        return;
    }

    if (time.timestamp() - timer.start > t) {
        std.process.exit(0);
    }
}

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: Devices = .{};

    var _fba = heap.FixedBufferAllocator.init(dev.ram[c8.memory.PROGRAM_START..]);
    const fba = _fba.allocator();

    c8.font.setFont(&dev.ram, &c8.font.font_chars);

    const rom = try c8.rom.Rom.read(Config.rom_file);
    rom.load(&dev.ram);
    try mainLoop(fba, &dev);
}

pub fn mainLoop(ally: Allocator, dev: *Devices) !void {
    _ = ally;
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
        exitTime(5);
    }
}
