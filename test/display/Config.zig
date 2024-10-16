const c8 = @import("chip8");

// memory
pub const stack_size = 100;

// display
pub const bg_color: c8.raylib.rl.Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const scale: u16 = 16;

// CPU
pub const cpu_delay_s: f64 = 0.0012; // Goal is 700 instructions per second

// Debug
pub const debug_timings_print_cycle: usize = 100;
