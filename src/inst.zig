const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;
const fmt = std.fmt;
const memory = @import("memory.zig");
const display = @import("display.zig");

const Addr = memory.Addr;
const Memory = memory.Memory;
const Screen = display.Screen;
const Devices = @import("main.zig").Devices;
const Config = @import("Config.zig");

// const HOST_ENDIAN = @import("builtin").cpu.arch.endian();

//TODO: Better handling of big endian platforms
pub const Inst = packed struct(u16) {
    nb4: u4 = 0x0,
    nb3: u4 = 0x0,
    nb2: u4 = 0x0,
    nb1: u4 = 0x0,

    pub fn execute(self: Inst, dev: *Devices) void {
        switch (self.nb1) {
            0x0 => switch (self.nb3) {
                0xe => {
                    if (self.nb4 == 0) {
                        clearScreen(&dev.screen);
                    } else {
                        noop();
                    }
                },
                0x0...0xd, 0xf => noop(),
            },
            0x1 => jump(@truncate(@as(u16, @bitCast(self))), &dev.pc),
            0x2 => call(@truncate(@as(u16, @bitCast(self))), dev),
            0x3...0xf => noop(),
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
    var dev: Devices = .{};

    dev.ram[memory.PROGRAM_START] = 0xf0;
    dev.ram[memory.PROGRAM_START + 1] = 0x0a;
    dev.ram[memory.PROGRAM_START + 2] = 0x5e;
    dev.ram[memory.PROGRAM_START + 3] = 0x01;

    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    const inst1 = dev.pc.fetch(&dev.ram);
    const inst2 = dev.pc.fetch(&dev.ram);

    try testing.expectEqual(0xf00a, @as(u16, @bitCast(inst1)));
    try testing.expectEqual(0x5e01, @as(u16, @bitCast(inst2)));
}

fn noop() void {
    return;
}

fn clearScreen(screen: *display.Screen) void {
    @memset(screen, .{0} ** display.HEIGHT);
}

fn jump(addr: Addr, pc: *ProgramCounter) void {
    pc.addr = addr;
}

test "execute jump instruction" {
    var dev: Devices = .{};

    dev.ram[memory.PROGRAM_START] = 0x12;
    dev.ram[memory.PROGRAM_START + 1] = 0x03;
    dev.ram[0x203] = 0x12;
    dev.ram[0x204] = 0x06;
    dev.ram[0x206] = 0xab;
    dev.ram[0x207] = 0xcd;

    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.pc.fetch(&dev.ram).execute(&dev);
    dev.pc.fetch(&dev.ram).execute(&dev);
    const inst = dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
}

fn call(addr: Addr, dev: *Devices) void {
    dev.stack.push(dev.pc.addr) catch @panic(fmt.comptimePrint("stackoverflow. Stack size set to {d}\n", .{Config.stack_size}));
    dev.pc.addr = addr;
}

test "execute call instruction" {
    var dev: Devices = .{};

    dev.ram[memory.PROGRAM_START] = 0x22;
    dev.ram[memory.PROGRAM_START + 1] = 0x05;
    dev.ram[0x205] = 0x22;
    dev.ram[0x206] = 0x08;
    dev.ram[0x208] = 0xab;
    dev.ram[0x209] = 0xcd;

    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.pc.fetch(&dev.ram).execute(&dev);
    dev.pc.fetch(&dev.ram).execute(&dev);
    const inst = dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
    try testing.expectEqual(0x207, dev.stack.pop() catch @panic("trying to pop empty stack\n"));
    try testing.expectEqual(0x202, dev.stack.pop() catch @panic("trying to pop empty stack\n"));
}

fn reverseNibbles(inst: Inst) Inst {
    var out: Inst = .{};
    out.nb1 = inst.nb4;
    out.nb2 = inst.nb3;
    out.nb3 = inst.nb2;
    out.nb4 = inst.nb1;
    return out;
}

test "reverseNibbles" {
    const num: u16 = 0x1234;
    const inst: Inst = @bitCast(num);
    const reversed: u16 = @bitCast(reverseNibbles(inst));
    try testing.expectEqual(0x4321, reversed);
}
