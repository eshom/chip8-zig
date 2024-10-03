const std = @import("std");
const log = std.log;
const rl = @import("raylib.zig").raylib;

const STANDARD_WIDTH = 64;
const STANDARD_HEIGHT = 32;

pub const DisplayOptions = struct {
    width: u16 = STANDARD_WIDTH,
    height: u16 = STANDARD_HEIGHT,
};

pub fn initWindow(title: [:0]const u8, options: DisplayOptions) void {
    rl.InitWindow(@intCast(options.width), @intCast(options.height), title.ptr);
}

pub fn closeWindow() void {
    rl.CloseWindow();
}

pub fn windowShouldClose() bool {
    return rl.WindowShouldClose();
}

pub fn beginDrawing() void {
    rl.BeginDrawing();
}

pub fn endDrawing() void {
    rl.EndDrawing();
}
