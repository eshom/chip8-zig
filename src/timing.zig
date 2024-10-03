const rl = @import("raylib.zig").raylib;

pub const Cycle = struct {
    total: u64 = 0,
    target_fps: f64 = 60,
    curr_time_s: f64,
    prev_time_s: f64,
    delta_time_s: f64,
    time_since_draw_s: f64 = 0,
    last_draw_delta_s: f64 = 0,
};

pub const waitTime = rl.WaitTime;
pub const getTime = rl.GetTime;
