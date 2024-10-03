pub const raylib = @cImport({
    @cInclude("raylib.h");
});

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

pub fn setLogLevel(log_level: TraceLogLevel) void {
    raylib.SetTraceLogLevel(@intFromEnum(log_level));
}
