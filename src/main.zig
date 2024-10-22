const std = @import("std");
const heap = std.heap;
const debug = std.debug;
const time = std.time;
const log = std.log;
const math = std.math;

const c8 = @import("chip8.zig");

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

    while (!c8.display.windowShouldClose()) : (dev.tick()) {
        c8.input.pollInputEvents();

        // Fetch instruction and execute
        const inst = try dev.pc.fetch(&dev.ram);
        inst.decode(dev);

        // Drawing happens here at 60 FPS (by default)
        if (dev.clock.time_since_draw_s > 1 / dev.clock.target_fps) {
            c8.display.beginDrawing();
            c8.display.clearBackground(Config.bg_color);
            // TODO: put dev.clock.time_since_draw_s reset in drawScreen call
            c8.display.drawScreen(&dev.screen, Config.scale, c8.raylib.rl.RAYWHITE);
            c8.display.endDrawing();
            c8.display.swapScreenBuffer();
            dev.clock.last_draw_delta_s = dev.clock.time_since_draw_s;
            dev.clock.time_since_draw_s = 0;
        }

        c8.timing.waitTime(Config.cpu_delay_s);
    }
}

test {
    _ = @import("chip8.zig");
}
