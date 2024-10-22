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
    .log_level = .debug,
};

fn loopAtEnd(dev: *Devices) void {
    dev.ram[0x2fe] = 0x12;
    dev.ram[0x2ff] = 0xfe;
}

fn drawTopLeftX(dev: *Devices, offset: u12) void {
    dev.ram[0x502] = 0b1000_1000;
    dev.ram[0x503] = 0b0101_0000;
    dev.ram[0x504] = 0b0010_0000;
    dev.ram[0x505] = 0b0101_0000;
    dev.ram[0x506] = 0b1000_1000;

    dev.ram[0x200 + offset] = 0x60;
    dev.ram[0x201 + offset] = 0x00;
    dev.ram[0x202 + offset] = 0xa5;
    dev.ram[0x203 + offset] = 0x02;
    dev.ram[0x204 + offset] = 0xd0;
    dev.ram[0x205 + offset] = 0x05;
}

fn drawChar(dev: *Devices, char: comptime_int, x: u8, y: u8, offset: u12) void {
    dev.ram[0x200 + offset] = 0x60;
    dev.ram[0x201 + offset] = x;
    dev.ram[0x202 + offset] = 0x61;
    dev.ram[0x203 + offset] = y;
    const addr: u12 = c8.font.charAddrOffset(char);
    const nibble: u4 = @truncate(addr >> 8);
    const lowerb: u8 = @truncate(addr);
    dev.ram[0x204 + offset] = 0xa0 | (@as(u8, nibble));
    dev.ram[0x205 + offset] = 0x00 | lowerb;
    dev.ram[0x206 + offset] = 0xd0;
    dev.ram[0x207 + offset] = 0x15;
}

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: Devices = Devices.init();
    c8.font.setFont(&dev.ram, &c8.font.font_chars);

    // write instructions to memory
    loopAtEnd(&dev);
    drawTopLeftX(&dev, 0x000 * 0);
    drawChar(&dev, 0x0, 6 * 1, 0, 0x008 * 1);
    drawChar(&dev, 0x1, 6 * 2, 0, 0x008 * 2);
    drawChar(&dev, 0x2, 6 * 3, 0, 0x008 * 3);
    drawChar(&dev, 0x3, 6 * 4, 0, 0x008 * 4);
    drawChar(&dev, 0x4, 6 * 5, 0, 0x008 * 5);
    drawChar(&dev, 0x5, 6 * 6, 0, 0x008 * 6);
    drawChar(&dev, 0x6, 6 * 7, 0, 0x008 * 7);
    drawChar(&dev, 0x7, 6 * 8, 0, 0x008 * 8);
    drawChar(&dev, 0x8, 6 * 9, 0, 0x008 * 9);
    drawChar(&dev, 0x9, 6 * 10, 0, 0x008 * 10);
    drawChar(&dev, 0xa, 6 * 0, 6, 0x008 * 11);
    drawChar(&dev, 0xb, 6 * 1, 6, 0x008 * 12);
    drawChar(&dev, 0xc, 6 * 2, 6, 0x008 * 13);
    drawChar(&dev, 0xc, 6 * 3, 6, 0x008 * 14);
    drawChar(&dev, 0xd, 6 * 4, 6, 0x008 * 15);
    drawChar(&dev, 0xe, 6 * 5, 6, 0x008 * 16);
    drawChar(&dev, 0xf, 6 * 6, 6, 0x008 * 17);
    c8.memory.debugDumpMemory((&dev.ram)[0x200..0x300], 16, 0x200);

    try mainLoop(&dev);
}

pub fn mainLoop(dev: *Devices) !void {
    const start_time = time.timestamp();
    const test_time = 5;
    c8.display.initWindow("CHIP-8", .{ .scale = Config.scale });
    defer c8.display.closeWindow();

    while (!c8.display.windowShouldClose()) : (dev.tick()) {
        c8.input.pollInputEvents();

        // Fetch instruction and execute
        const inst = try dev.pc.fetch(&dev.ram);
        inst.decode(dev);

        // Drawing happens here at 60 FPS (by default)
        if (dev.clock.time_since_draw_s > 1 / dev.clock.target_fps) {
            c8.display.beginDrawing();
            c8.display.clearBackground(Config.bg_color);
            c8.display.drawScreen(&dev.screen, Config.scale, c8.raylib.rl.RAYWHITE);
            c8.display.endDrawing();
            c8.display.swapScreenBuffer();
            dev.clock.last_draw_delta_s = dev.clock.time_since_draw_s;
            dev.clock.time_since_draw_s = 0;
        }

        c8.timing.waitTime(Config.cpu_delay_s);

        if (time.timestamp() - start_time > test_time) {
            break;
        }
    }
}
