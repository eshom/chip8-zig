const std = @import("std");
const time = std.time;
const heap = std.heap;
const log = std.log;

const c8 = @import("chip8");

const Config = @import("Config.zig");

const Devices = c8.Devices;

pub const std_options = .{
    .log_level = .debug,
};

pub fn main() !void {
    c8.raylib.setLogLevel(.log_error);
    var dev: c8.Devices = c8.Devices.init();
    try mainLoop(&dev);
}

pub fn mainLoop(dev: *Devices) !void {
    const start_time = time.timestamp();
    const test_time = 5;

    c8.timing.initAudioDevice();
    c8.timing.setMasterVolume(Config.initial_volume);
    const beep = c8.timing.loadSound(dev.sound_timer.sound);

    c8.display.initWindow("CHIP-8", .{ .scale = Config.scale });
    defer c8.display.closeWindow();

    const debug_start_time = time.microTimestamp();
    var debug_curr_time = debug_start_time;
    var debug_last_print_time_us = debug_curr_time;

    // temp stuff to have on screen
    dev.screen[16][16] = 1;
    dev.screen[32][16] = 1;
    dev.screen[48][16] = 1;
    dev.screen[32][24] = 1;
    dev.screen[32][8] = 1;
    // temporary timer
    dev.sound_timer.timer = 240;

    while (!c8.display.windowShouldClose()) : ({
        dev.tick();
        debug_curr_time = time.microTimestamp();
    }) {
        c8.input.pollInputEvents();

        if (dev.delay_timer.timer != 0 and dev.delay_timer.last_tick_s > dev.delay_timer.rate) {
            dev.delay_timer.timer -= 1;
            dev.delay_timer.last_tick_s = 0;
        }

        if (dev.sound_timer.timer != 0 and dev.sound_timer.last_tick_s > dev.sound_timer.rate) {
            dev.sound_timer.timer -= 1;
            if (dev.sound_timer.timer == 0) {
                c8.timing.playSound(beep);
            }
            dev.sound_timer.last_tick_s = 0;
        }

        if (dev.clock.time_since_draw_s > 1 / dev.clock.target_fps) {
            // Drawing start
            c8.display.beginDrawing();
            c8.display.clearBackground(Config.bg_color);
            c8.display.drawScreen(&dev.screen, Config.scale, c8.raylib.rl.RAYWHITE);

            // temporary check
            if (dev.sound_timer.timer == 0) {
                dev.sound_timer.timer = 240;
                // clearScreen when timer goes out
                (c8.inst.Inst{ .nb3 = 0xe }).decode(dev);
            }

            c8.display.endDrawing();
            c8.display.swapScreenBuffer();
            dev.clock.last_draw_delta_s = dev.clock.time_since_draw_s;
            dev.clock.time_since_draw_s = 0;
            // Drawing end
        }

        c8.timing.waitTime(Config.cpu_delay_s);

        // Debug stuff
        if (dev.clock.total % Config.debug_timings_print_cycle == 0) {
            log.debug("run time us: {d}, total cycle: {d}, last cycle time us: {d}, last print time us: {d}, time since last update: {d:.4}, last draw delta: {d:.4}", .{
                time.microTimestamp() - debug_start_time,
                dev.clock.total,
                time.microTimestamp() - debug_curr_time,
                time.microTimestamp() - debug_last_print_time_us,
                dev.clock.time_since_draw_s,
                dev.clock.last_draw_delta_s,
            });
            debug_last_print_time_us = time.microTimestamp();
            log.debug("cycle: {d}, time since last tick: {d:.4}, sound timer: {d}", .{ dev.clock.total, dev.sound_timer.last_tick_s, dev.sound_timer.timer });
        }

        if (time.timestamp() - start_time > test_time) {
            break;
        }
    }
}
