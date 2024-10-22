const c8 = @import("chip8");

// memory
pub const stack_size = 100;
pub const rom_file = "roms/3-corax+.ch8";

// display
pub const bg_color: c8.raylib.rl.Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const scale: u16 = 16;

// CPU
pub const cpu_delay_s: f64 = 0.0012; // Goal is 700 instructions per second
// pub const cpu_delay_s: f64 = 0.0024;

// Quirks
pub const original_bitshift = true;
pub const original_memory_load_store = false;
pub const flag_index_register_overflow = false;
pub const original_b_jump = true;
pub const original_get_key_upon_release = false;

// Debug
pub const debug_timings_print_cycle: usize = 100;
