const std = @import("std");
const log = std.log;
const rl = @import("raylib.zig").raylib;

pub const SCALING_FACTOR = 16;
const STANDARD_WIDTH = 64 * SCALING_FACTOR;
const STANDARD_HEIGHT = 32 * SCALING_FACTOR;

pub const DisplayOptions = struct {
    width: u16 = STANDARD_WIDTH,
    height: u16 = STANDARD_HEIGHT,
};

pub const closeWindow = rl.CloseWindow;
pub const windowShouldClose = rl.WindowShouldClose;
pub const beginDrawing = rl.BeginDrawing;
pub const endDrawing = rl.EndDrawing;
pub const swapScreenBuffer = rl.SwapScreenBuffer;
pub const clearBackground = rl.ClearBackground;

pub fn initWindow(title: [:0]const u8, options: DisplayOptions) void {
    rl.InitWindow(@intCast(options.width), @intCast(options.height), title.ptr);
}
