const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;
const memory = @import("memory.zig");
const display = @import("display.zig");

const Addr = memory.Addr;
const Memory = memory.Memory;
const Screen = display.Screen;

fn noop() void {
    return;
}

pub const Inst = packed struct(u16) {
    nb1: u4 = 0x0,
    nb2: u4 = 0x0,
    nb3: u4 = 0x0,
    nb4: u4 = 0x0,

    pub fn execute(self: Inst) void {
        switch (self.nb1) {
            0x0 => switch (self.nb3) {
                0xe => {
                    if (self.nb4 == 0) {
                        clearScreen(&display.screen);
                    } else {
                        noop();
                    }
                },
                0x0...0xd, 0xf => noop(),
            },
            0x1...0xf => noop(),
        }
    }
};

pub const ProgramCounter = struct {
    addr: Addr = memory.PROGRAM_START,

    pub fn fetch(self: *ProgramCounter, memo: *const Memory) Inst {
        const inst = mem.readInt(u16, &[2]u8{ memo[self.addr], memo[self.addr + 1] }, .big);
        self.addr += 0x002;
        return @bitCast(inst);
    }
};

test "Progmemory.ramCounter.fetch" {
    memory.ram[memory.PROGRAM_START] = 0xf0;
    memory.ram[memory.PROGRAM_START + 1] = 0x0a;
    memory.ram[memory.PROGRAM_START + 2] = 0x5e;
    memory.ram[memory.PROGRAM_START + 3] = 0x01;

    debug.assert(pc.addr == memory.PROGRAM_START);
    const inst1 = pc.fetch(&memory.ram);
    const inst2 = pc.fetch(&memory.ram);

    try testing.expectEqual(0xf00a, @as(u16, @bitCast(inst1)));
    try testing.expectEqual(0x5e01, @as(u16, @bitCast(inst2)));
}

pub var pc: ProgramCounter = .{};

fn clearScreen(screen: *display.Screen) void {
    @memset(screen, .{0} ** display.HEIGHT);
}
