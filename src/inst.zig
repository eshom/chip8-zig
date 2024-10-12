const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;
const memory = @import("memory.zig");
const display = @import("display.zig");

const Addr = memory.Addr;
const Memory = memory.Memory;
const Screen = display.Screen;

pub const Inst = packed struct(u16) {
    nb1: u4 = 0x0,
    nb2: u4 = 0x0,
    nb3: u4 = 0x0,
    nb4: u4 = 0x0,

    pub fn execute(self: Inst, progc: *ProgramCounter, sc: *Screen) void {
        switch (self.nb1) {
            0x0 => switch (self.nb3) {
                0xe => {
                    if (self.nb4 == 0) {
                        clearScreen(sc);
                    } else {
                        noop();
                    }
                },
                0x0...0xd, 0xf => noop(),
            },
            0x1 => jump(@truncate(@as(u16, @bitCast(self))), progc),
            0x2...0xf => noop(),
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

test "ProgramCounter.fetch" {
    var ram: Memory = .{0} ** memory.TOTAL_MEM;
    var p: ProgramCounter = .{};

    ram[memory.PROGRAM_START] = 0xf0;
    ram[memory.PROGRAM_START + 1] = 0x0a;
    ram[memory.PROGRAM_START + 2] = 0x5e;
    ram[memory.PROGRAM_START + 3] = 0x01;

    debug.assert(p.addr == memory.PROGRAM_START);
    const inst1 = p.fetch(&ram);
    const inst2 = p.fetch(&ram);

    try testing.expectEqual(0xf00a, @as(u16, @bitCast(inst1)));
    try testing.expectEqual(0x5e01, @as(u16, @bitCast(inst2)));
}

fn noop() void {
    return;
}

fn clearScreen(screen: *display.Screen) void {
    @memset(screen, .{0} ** display.HEIGHT);
}

fn jump(addr: Addr, progc: *ProgramCounter) void {
    progc.addr = addr;
}

test "execute jump instruction" {
    var ram: Memory = .{0} ** memory.TOTAL_MEM;
    var p: ProgramCounter = .{};
    var screen: Screen = .{.{0} ** display.HEIGHT} ** display.WIDTH;

    ram[memory.PROGRAM_START] = 0x12;
    ram[memory.PROGRAM_START + 1] = 0x02;
    ram[0x202] = 0x12;
    ram[0x203] = 0x04;
    ram[0x204] = 0xaa;
    ram[0x205] = 0xaa;

    debug.assert(p.addr == memory.PROGRAM_START);
    p.fetch(&ram).execute(&p, &screen);
    p.fetch(&ram).execute(&p, &screen);
    const inst = p.fetch(&ram);
    try testing.expectEqual(0xaaaa, @as(u16, @bitCast(inst)));
}
