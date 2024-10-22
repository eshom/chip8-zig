const std = @import("std");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;
const math = std.math;

const c8 = @import("chip8");
const options = @import("options");

const Memory = c8.memory.Memory;
const Devices = c8.Devices;
const Rom = c8.rom.Rom;
const Config = @import("Config.zig");

pub const std_options = .{
    .log_level = .debug,
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

fn totalTime(t: i64) i64 {
    const timer = struct {
        var start: i64 = -1;
    };

    if (timer.start == -1) {
        timer.start = time.timestamp();
        return 0;
    }

    const delta = time.timestamp() - timer.start;

    if (delta > t) {
        timer.start = time.timestamp();
    }

    return delta;
}

fn changeRom(rom: *const Rom, rompath: []const u8, memo: *Memory) !Rom {
    rom.unload(memo);
    const new_rom = try Rom.read(rompath);
    new_rom.load(memo);
    return new_rom;
}

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: Devices = Devices.init();
    try mainLoop(&dev);
}

pub fn mainLoop(dev: *Devices) !void {
    c8.display.initWindow("CHIP-8", .{ .scale = Config.scale });
    defer c8.display.closeWindow();

    var rom_idx: usize = 1;
    const rom_paths: []const []const u8 = &.{
        "roms/1-chip8-logo.ch8",
        "roms/2-ibm-logo-test.ch8",
        "roms/3-corax+.ch8",
        "roms/4-flags.ch8",
        "roms/5-quirks.ch8",
        "roms/6-keypad.ch8",
    };

    var rom: Rom = undefined;

    if (options.test_number != 0) {
        if (options.test_number > rom_paths.len) {
            return error.TestDoesNotExist;
        }
        rom = try c8.rom.Rom.read(rom_paths[options.test_number - 1]);
    } else {
        rom = try c8.rom.Rom.read(rom_paths[0]);
    }

    rom.load(&dev.ram);

    _ = totalTime(options.test_time);
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

        if (totalTime(options.test_time) > options.test_time) {
            if (options.test_number != 0) {
                break;
            }
            if (rom_idx >= rom_paths.len) {
                break; // no more roms to run
            }
            dev.reset();
            c8.font.setFont(&dev.ram, &c8.font.font_chars);
            rom = try changeRom(&rom, rom_paths[rom_idx], &dev.ram);
            rom_idx += 1;
            // if (rom_idx == 4) {
            //     dev.ram[0x1ff] = 1; // quirks test choice CHIP-8
            // }
        }
    }
}
