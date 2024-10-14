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
const Reg = memory.Reg;
const Config = @import("Config.zig");

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
                    if (self.nb4 == 0x0 and self.nb2 == 0x0) {
                        clearScreen(&dev.screen);
                    } else if (self.nb4 == 0xe and self.nb2 == 0x0) {
                        ret(dev);
                    } else {
                        noop(); // unsupported instruction `0NNN`
                    }
                },
                0x0...0xd, 0xf => noop(),
            },
            0x1 => jump(@truncate(@as(u16, @bitCast(self))), &dev.pc),
            0x2 => call(@truncate(@as(u16, @bitCast(self))), dev),
            0x6 => set(self.nb2, @truncate(@as(u16, @bitCast(self))), &dev.reg),
            0x7 => add(self.nb2, @truncate(@as(u16, @bitCast(self))), &dev.reg),
            0xa => setI(@truncate(@as(u16, @bitCast(self))), &dev.reg),
            0xd => displayI(self.nb2, self.nb3, self.nb4, dev),
            0x3...0x5, 0x8...0x9, 0xb, 0xc, 0xe...0xf => noop(),
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

fn ret(dev: *Devices) void {
    dev.pc.addr = dev.stack.pop() catch @panic("trying to pop out of empty stack");
}

test "execute ret instruction" {
    var dev: Devices = .{};
    dev.ram[memory.PROGRAM_START] = 0x22;
    dev.ram[memory.PROGRAM_START + 1] = 0x05;
    dev.ram[0x205] = 0x00;
    dev.ram[0x206] = 0xee;
    dev.ram[0x202] = 0xab;
    dev.ram[0x203] = 0xcd;

    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.pc.fetch(&dev.ram).execute(&dev);
    dev.pc.fetch(&dev.ram).execute(&dev);
    const inst = dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
}

fn set(dest_reg: u4, value: u8, reg: *Reg) void {
    reg.v[dest_reg] = value;
}

test "execute set instruction" {
    var dev: Devices = .{};
    dev.ram[memory.PROGRAM_START] = 0x64;
    dev.ram[memory.PROGRAM_START + 1] = 0x33;
    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0x33, dev.reg.v[4]);
}

fn add(dest_reg: u4, value: u8, reg: *Reg) void {
    reg.v[dest_reg] +|= value;
}

test "execute add instruction" {
    var dev: Devices = .{};
    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0x65;
    dev.ram[dev.pc.addr + 1] = 0x33;
    dev.pc.fetch(&dev.ram).execute(&dev);
    dev.ram[dev.pc.addr] = 0x75;
    dev.ram[dev.pc.addr + 1] = 0x33;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0x66, dev.reg.v[5]);

    dev.ram[dev.pc.addr] = 0x75;
    dev.ram[dev.pc.addr + 1] = 0xff;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0xff, dev.reg.v[5]);
}

fn setI(value: Addr, reg: *Reg) void {
    reg.i = value;
}

test "execute setI instruction" {
    var dev: Devices = .{};
    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0xa2;
    dev.ram[dev.pc.addr + 1] = 0x00;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0x200, dev.reg.i);

    dev.ram[dev.pc.addr] = 0xa2;
    dev.ram[dev.pc.addr + 1] = 0x50;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0x250, dev.reg.i);

    dev.ram[dev.pc.addr] = 0xaf;
    dev.ram[dev.pc.addr + 1] = 0xff;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0xfff, dev.reg.i);
}

fn displayI(reg_x: u4, reg_y: u4, rows: u4, dev: *Devices) void {
    var pos_x: usize = dev.reg.v[reg_x] % display.WIDTH;
    var pos_y: usize = dev.reg.v[reg_y] % display.HEIGHT;
    dev.reg.v[0xf] = 0;

    for (0..rows) |row| {
        if (pos_y >= display.HEIGHT) {
            break;
        }
        // TODO: Overflow check maybe
        const sprite_byte = dev.ram[dev.reg.i + row];
        var idx: i4 = 7;
        while (idx >= 0) : (idx -= 1) {
            const pixel: u1 = @truncate(sprite_byte >> @intCast(idx));
            if (pos_x >= display.WIDTH) {
                break;
            }
            if (pixel == 1 and dev.screen[pos_x][pos_y] == 1) {
                dev.screen[pos_x][pos_y] = 0;
                dev.reg.v[0xf] = 1;
            } else if (pixel == 1 and dev.screen[pos_x][pos_y] == 0) {
                dev.screen[pos_x][pos_y] = 1;
            }
            pos_x += 1;
        }
        pos_y += 1;
    }
}

test "execute displayI instruction" {
    var dev: Devices = .{};
    debug.assert(dev.pc.addr == memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0xd0;
    dev.ram[dev.pc.addr + 1] = 0x11;
    dev.reg.v[0] = 1;
    dev.reg.v[1] = 16;
    dev.reg.i = 0x250;
    dev.ram[dev.reg.i] = 0b1111_1111;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(0, dev.reg.v[0xf]);

    var actual: [8]u1 = undefined;

    for (1..9, 0..) |screen_i, idx| {
        actual[idx] = dev.screen[screen_i][16];
    }

    try testing.expectEqualSlices(u1, &[_]u1{1} ** 8, &actual);

    dev.ram[dev.pc.addr] = 0xd0;
    dev.ram[dev.pc.addr + 1] = 0x11;
    dev.ram[dev.reg.i] = 0b1000_1000;
    dev.pc.fetch(&dev.ram).execute(&dev);
    try testing.expectEqual(1, dev.reg.v[0xf]);

    for (1..9, 0..) |screen_i, idx| {
        actual[idx] = dev.screen[screen_i][16];
    }

    try testing.expectEqualSlices(u1, &[_]u1{ 0, 1, 1, 1, 0, 1, 1, 1 }, &actual);
}