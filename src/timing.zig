const rl = @import("raylib.zig").raylib;

pub const Cycle = struct {
    total: u64 = 0,
    start_time_us: i64,
};

pub fn setTargetFPS(fps: u16) void {
    rl.SetTargetFPS(@intCast(fps));
}

pub fn waitTime(seconds: f64) void {
    rl.WaitTime(seconds);
}
