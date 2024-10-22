const std = @import("std");
const log = std.log;
const debug = std.debug;
const c8 = @import("chip8.zig");
const rl = c8.raylib.rl;

pub const WIDTH = 64;
pub const HEIGHT = 32;

pub const Screen = [WIDTH][HEIGHT]u1;

pub const DisplayOptions = struct {
    width: u16 = WIDTH,
    height: u16 = HEIGHT,
    scale: u16 = 1,
};

pub const closeWindow = rl.CloseWindow;
pub const windowShouldClose = rl.WindowShouldClose;
pub const beginDrawing = rl.BeginDrawing;
pub const endDrawing = rl.EndDrawing;
pub const swapScreenBuffer = rl.SwapScreenBuffer;
pub const clearBackground = rl.ClearBackground;
pub const setConfigFlags = rl.SetConfigFlags;

pub fn initWindow(title: [:0]const u8, options: DisplayOptions) void {
    comptime std.debug.assert(@bitSizeOf(c_int) == @bitSizeOf(i32));
    rl.InitWindow(@intCast(options.width * options.scale), @intCast(options.height * options.scale), title.ptr);
}

fn drawPixel(pos_x: i32, pos_y: i32, color: rl.Color) void {
    comptime std.debug.assert(@bitSizeOf(c_int) == @bitSizeOf(i32));
    rl.DrawPixel(pos_x, pos_y, color);
}

fn drawPixelScaled(pos_x_left: i32, pos_y_top: i32, scale: u16, color: rl.Color) void {
    comptime std.debug.assert(@bitSizeOf(c_int) == @bitSizeOf(i32));
    rl.DrawRectangle(pos_x_left * scale, pos_y_top * scale, scale, scale, color);
}

pub fn drawScreen(scr: *const Screen, scale: u16, color: rl.Color) void {
    var x: u16 = 0;
    var y: u16 = 0;

    while (x < scr.len) : (x += 1) {
        defer y = 0;
        while (y < scr[x].len) : (y += 1) {
            if (scr[x][y] == 1) {
                drawPixelScaled(x, y, scale, color);
            }
        }
    }
}

pub fn debugDumpScreen(scr: *const Screen) void {
    for (0..WIDTH) |col| {
        for (0..HEIGHT) |row| {
            std.debug.print("{d}", .{scr[col][row]});
        }
        std.debug.print("\n", .{});
    }
}

// TODO: This test
// test "drawing to screen happens" {}
