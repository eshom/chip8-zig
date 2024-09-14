const rl = @cImport({
    @cInclude("raylib.h");
});

const STANDARD_WIDTH = 64;
const STANDARD_HEIGHT = 32;

pub const TraceLogLevel = enum(c_int) {
    log_all = 0,
    log_trace,
    log_debug,
    log_info,
    log_warning,
    log_error,
    log_fatal,
    log_none,
};

pub const DisplayOptions = struct {
    width: u16 = STANDARD_WIDTH,
    height: u16 = STANDARD_HEIGHT,
};

pub fn setLogLevel(log_level: TraceLogLevel) void {
    rl.SetTraceLogLevel(@intFromEnum(log_level));
}

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
