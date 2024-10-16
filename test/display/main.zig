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
const Config = c8.Config;

pub const std_options = .{
    .log_level = .debug,
};

fn loopAtEnd(dev: *Devices) void {
    dev.ram[0x500] = 0x15;
    dev.ram[0x501] = 0x00;
}

fn drawTopLeftX(dev: *Devices) void {
    dev.reg.v[0] = 0;
    dev.reg.i = 0x502;
    dev.ram[0x502] = 0b1000_0001;
    dev.ram[0x503] = 0b0100_0010;
    dev.ram[0x504] = 0b0010_0100;
    dev.ram[0x505] = 0b0001_1000;
    dev.ram[0x506] = 0b0001_1000;
    dev.ram[0x507] = 0b0010_0100;
    dev.ram[0x508] = 0b0100_0010;
    dev.ram[0x509] = 0b1000_0001;

    dev.ram[0x200] = 0xd0;
    dev.ram[0x201] = 0x08;
}

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: Devices = .{};

    var _fba = heap.FixedBufferAllocator.init(dev.ram[c8.memory.PROGRAM_START..]);
    const fba = _fba.allocator();

    // write instructions to memory
    loopAtEnd(&dev);
    drawTopLeftX(&dev);

    try mainLoop(fba, &dev);
}

pub fn mainLoop(ally: Allocator, dev: *Devices) !void {
    _ = ally;

    const start_time = time.timestamp();
    const test_time = 5;
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

        if (time.timestamp() - start_time > test_time) {
            break;
        }
    }
}
