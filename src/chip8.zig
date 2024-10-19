pub const memory = @import("memory.zig");
pub const font = @import("font.zig");
pub const display = @import("display.zig");
pub const timing = @import("timing.zig");
pub const raylib = @import("raylib.zig");
pub const input = @import("input.zig");
pub const inst = @import("inst.zig");
pub const rom = @import("rom.zig");

const std = @import("std");

pub const Config = @import("Config.zig");

/// RNG is undefined until `.init` is called for the first time
/// So don't create this without `.init`
pub const Devices = struct {
    pc: inst.ProgramCounter = .{},
    ram: memory.Memory = .{0} ** memory.TOTAL_MEM,
    stack: memory.Stack(Config.stack_size) = .{},
    reg: memory.Reg = .{},
    screen: display.Screen = .{.{0} ** display.HEIGHT} ** display.WIDTH,
    delay_timer: timing.DelayTimer = .{},
    sound_timer: timing.SoundTimer = .{},
    rom: ?rom.Rom = null,
    rng: std.Random = rng_algo.random(),

    var rng_algo: std.Random.DefaultPrng = undefined;

    pub fn reset(self: *Devices) void {
        self.pc = inst.ProgramCounter{};
        @memset(&self.ram, 0); // fonts need to be reloaded
        self.stack = memory.Stack(Config.stack_size){};
        self.reg = memory.Reg{};
        for (&self.screen) |*row| {
            @memset(row, 0);
        }
        self.delay_timer = timing.DelayTimer{};
        self.sound_timer = timing.SoundTimer{};
    }

    pub fn loadFont(self: *Devices) void {
        font.setFont(&self.ram, &font.font_chars);
    }

    pub fn init() Devices {
        Devices.rng_algo = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
        var out = Devices{};
        out.loadFont();
        return out;
    }

    pub fn loadRom(self: *Devices, rompath: []const u8) !void {
        if (self.rom) |_| {
            return DeviceError.RomAlreadyLoaded;
        }
        const out = try rom.Rom.read(rompath);
        out.load(&self.ram);
    }
};

pub const ProgramError = error{
    UnexpectedProgramEnd,
    RomTooBig,
};

pub const DeviceError = error{
    RomAlreadyLoaded,
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
