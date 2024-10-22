const std = @import("std");
const testing = std.testing;
const mem = std.mem;

const raylib = @import("raylib.zig");
const rl = raylib.rl;
const display = @import("display.zig");
const c8 = @import("chip8.zig");

const Devices = c8.Devices;
const Cycle = c8.Clock;

pub const DelayTimer = struct {
    timer: u8 = 0,
    last_tick_s: f64 = 0,
    rate: f64 = 0.01666,

    pub fn tick(self: *DelayTimer, dev: *Devices) void {
        _ = self; // autofix
        _ = dev; // autofix

    }
};

pub const SoundTimer = struct {
    timer: u8 = 0,
    last_tick_s: f64 = 0,
    rate: f64 = 0.01666,
    sound: [:0]const u8 = "res/beep.wav",
};

pub const waitTime = rl.WaitTime;
pub const getTime = rl.GetTime;
pub const initAudioDevice = rl.InitAudioDevice;
pub const playSound = rl.PlaySound;
pub const getMasterVolume = rl.GetMasterVolume;
pub const setMasterVolume = rl.SetMasterVolume;

pub fn loadSound(filename: [:0]const u8) rl.Sound {
    return rl.LoadSound(filename);
}

test "timers timing" {
    raylib.setLogLevel(.log_none);
    display.setConfigFlags(rl.FLAG_WINDOW_HIDDEN);
    display.initWindow("timers timing", .{});
    defer display.closeWindow();

    var cycles = c8.Clock{
        .curr_time_s = getTime(),
        .prev_time_s = undefined,
        .delta_time_s = undefined,
    };
    cycles.prev_time_s = cycles.curr_time_s;
    cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;

    const start_time = getTime();

    var timers: [8]DelayTimer = .{DelayTimer{}} ** 8;
    const increment: usize = 15;
    for (&timers, 0..) |*tm, idx| {
        tm.timer = @intCast((idx + 1) * increment);
    }
    var end_times: [8]f64 = .{0} ** 8;
    var done: [8]bool = .{false} ** 8;

    while (!display.windowShouldClose()) : ({
        cycles.total +%= 1;
        cycles.delta_time_s = cycles.curr_time_s - cycles.prev_time_s;
        cycles.prev_time_s = cycles.curr_time_s;
        cycles.curr_time_s = getTime();
        inline for (&timers) |*tm| {
            if (tm.timer != 0) tm.last_tick_s += cycles.delta_time_s;
        }
    }) {
        inline for (&timers) |*tm| {
            if (tm.timer != 0 and tm.last_tick_s > tm.rate) {
                tm.timer -= 1;
                tm.last_tick_s = 0;
            }
        }

        inline for (&timers, 0..) |*tm, idx| {
            if (tm.timer == 0 and !done[idx]) {
                end_times[idx] = cycles.curr_time_s - start_time;
                done[idx] = true;
            }
        }

        const done2: [8]bool = .{true} ** 8;
        if (mem.eql(bool, &done, &done2)) {
            std.debug.print("timers ended: {d:.4}\n", .{end_times});
            inline for (end_times, 0..) |end, idx| {
                try testing.expectApproxEqRel(0.25 * @as(f64, (idx + 1)), end, 0.050);
            }
            break;
        }

        waitTime(0.001);
    }
}
