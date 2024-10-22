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

pub const Clock = struct {
    total: u64 = 0,
    target_fps: f64 = 60,
    curr_time_s: f64,
    prev_time_s: f64,
    delta_time_s: f64,
    time_since_draw_s: f64 = 0,
    last_draw_delta_s: f64 = 0,
};

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
    clock: Clock,

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
        var out = Devices{
            .clock = Clock{
                .curr_time_s = timing.getTime(),
                .prev_time_s = undefined,
                .delta_time_s = undefined,
            },
        };
        out.clock.prev_time_s = out.clock.curr_time_s;
        out.clock.delta_time_s = out.clock.curr_time_s - out.clock.prev_time_s;
        out.loadFont();
        timing.initAudioDevice();
        timing.setMasterVolume(Config.initial_volume);
        return out;
    }

    pub fn loadRom(self: *Devices, rompath: []const u8) !void {
        if (self.rom) |_| {
            return DeviceError.RomAlreadyLoaded;
        }
        const out = try rom.Rom.read(rompath);
        out.load(&self.ram);
    }

    pub fn tick(self: *Devices) void {
        self.clock.total +%= 1;
        self.clock.delta_time_s = self.clock.curr_time_s - self.clock.prev_time_s;
        self.clock.prev_time_s = self.clock.curr_time_s;
        self.clock.curr_time_s = timing.getTime();
        self.clock.time_since_draw_s += self.clock.delta_time_s;
        if (self.delay_timer.timer != 0) {
            self.delay_timer.last_tick_s += self.clock.delta_time_s;
            if (self.delay_timer.last_tick_s > self.delay_timer.rate) {
                self.delay_timer.timer -= 1;
                self.delay_timer.last_tick_s = 0;
            }
        }
        if (self.sound_timer.timer != 0) {
            self.sound_timer.last_tick_s += self.clock.delta_time_s;
            if (self.sound_timer.last_tick_s > self.sound_timer.rate) {
                self.sound_timer.timer -= 1;
                self.sound_timer.last_tick_s = 0;
                if (self.sound_timer.timer == 0) {
                    if (timing.SoundTimer.beep) |bp| {
                        timing.playSound(bp);
                    }
                }
            }
        }
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
