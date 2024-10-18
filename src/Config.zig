const c8 = @import("chip8.zig");

// Memory
pub const stack_size = 100;
pub const rom_file = "roms/2-ibm-logo-test.ch8";

// Display
pub const bg_color: c8.raylib.rl.Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const scale = 16;

// CPU
pub const cpu_delay_s = 0.0012; // Goal is 700 instructions per second
pub const original_bitshift = true;
pub const original_memory_load_store = false;
pub const flag_index_register_overflow = false;

// Debug
pub const debug_timings_print_cycle = 100;

// Sound
pub const initial_volume: f32 = 0.5;
