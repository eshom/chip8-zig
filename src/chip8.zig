pub const memory = @import("memory.zig");
pub const font = @import("font.zig");
pub const display = @import("display.zig");
pub const timing = @import("timing.zig");
pub const raylib = @import("raylib.zig");
pub const input = @import("input.zig");
pub const inst = @import("inst.zig");
pub const rom = @import("rom.zig");

pub const Config = @import("Config.zig");

pub const Devices = struct {
    pc: inst.ProgramCounter = .{},
    ram: memory.Memory = .{0} ** memory.TOTAL_MEM,
    stack: memory.Stack(Config.stack_size) = .{},
    reg: memory.Reg = .{},
    screen: display.Screen = .{.{0} ** display.HEIGHT} ** display.WIDTH,
    delay_timer: timing.DelayTimer = .{},
    sound_timer: timing.SoundTimer = .{},
};

pub const ProgramError = error{
    UnexpectedProgramEnd,
    RomTooBig,
};

test {
    _ = @import("memory.zig");
    _ = @import("font.zig");
    _ = @import("display.zig");
    _ = @import("timing.zig");
    _ = @import("raylib.zig");
    _ = @import("input.zig");
    _ = @import("inst.zig");
    _ = @import("Config.zig");
    _ = @import("rom.zig");
}
