const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;
const fmt = std.fmt;
const log = std.log;

const c8 = @import("chip8.zig");

const Addr = c8.memory.Addr;
const Memory = c8.memory.Memory;
const Screen = c8.display.Screen;
const Devices = c8.Devices;
const Reg = c8.memory.Reg;
const Config = @import("Config.zig");

pub const Inst = packed struct(u16) {
    nb4: u4 = 0x0, // least significant
    nb3: u4 = 0x0,
    nb2: u4 = 0x0,
    nb1: u4 = 0x0, // most significant

    pub fn decode(self: Inst, dev: *Devices) void {
        const lower_byte: u8 = @truncate(@as(u16, @bitCast(self)));
        const lower_three: u12 = @truncate(@as(u16, @bitCast(self)));
        switch (self.nb1) {
            0x0 => switch (self.nb3) {
                0xe => {
                    if (self.nb4 == 0x0 and self.nb2 == 0x0) {
                        clearScreen(dev);
                    } else if (self.nb4 == 0xe and self.nb2 == 0x0) {
                        ret(dev);
                    } else {
                        noop(); // unsupported instruction `0NNN`
                    }
                },
                else => noop(),
            },
            0x1 => jump(lower_three, dev),
            0x2 => call(lower_three, dev),
            0x3 => skipEqX(self.nb2, lower_byte, dev),
            0x4 => skipNotEqX(self.nb2, lower_byte, dev),
            0x5 => skipEqXY(self.nb2, self.nb3, dev),
            0x6 => setX(self.nb2, lower_byte, dev),
            0x7 => addX(self.nb2, lower_byte, dev),
            0x8 => switch (self.nb4) {
                0x0 => setXY(self.nb2, self.nb3, dev),
                0x1 => orXY(self.nb2, self.nb3, dev),
                0x2 => andXY(self.nb2, self.nb3, dev),
                0x3 => xorXY(self.nb2, self.nb3, dev),
                0x4 => addXY(self.nb2, self.nb3, dev),
                0x5 => subXY(self.nb2, self.nb3, dev),
                0x6 => shrXY(self.nb2, self.nb3, dev, Config.original_bitshift),
                0x7 => subYX(self.nb2, self.nb3, dev),
                0xe => shlXY(self.nb2, self.nb3, dev, Config.original_bitshift),
                else => noop(),
            },
            0x9 => skipNotEqXY(self.nb2, self.nb3, dev),
            0xa => setI(lower_three, dev),
            0xd => displayI(self.nb2, self.nb3, self.nb4, dev),
            0xf => switch (self.nb3) {
                0x1 => switch (self.nb4) {
                    0xe => addI(self.nb2, dev, Config.flag_index_register_overflow),
                    else => noop(),
                },
                0x3 => bcdc(self.nb2, dev),
                0x5 => memStore(self.nb2, dev, Config.original_memory_load_store),
                0x6 => memLoad(self.nb2, dev, Config.original_memory_load_store),
                else => noop(),
            },
            else => noop(),
        }
    }
};

pub const ProgramCounter = struct {
    addr: Addr = c8.memory.PROGRAM_START,

    pub fn fetch(self: *ProgramCounter, memo: *const Memory) !Inst {
        if (self.addr > memo.len - 2) {
            return c8.ProgramError.UnexpectedProgramEnd;
        }
        const inst = mem.readInt(u16, &[2]u8{ memo[self.addr], memo[self.addr + 1] }, .big);
        self.addr +|= 0x002;
        return @bitCast(inst);
    }
};

test "ProgramCounter.fetch" {
    var dev: Devices = .{};

    dev.ram[c8.memory.PROGRAM_START] = 0xf0;
    dev.ram[c8.memory.PROGRAM_START + 1] = 0x0a;
    dev.ram[c8.memory.PROGRAM_START + 2] = 0x5e;
    dev.ram[c8.memory.PROGRAM_START + 3] = 0x01;

    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    const inst1 = try dev.pc.fetch(&dev.ram);
    const inst2 = try dev.pc.fetch(&dev.ram);

    try testing.expectEqual(0xf00a, @as(u16, @bitCast(inst1)));
    try testing.expectEqual(0x5e01, @as(u16, @bitCast(inst2)));
}

fn noop() void {
    return;
}

fn clearScreen(dev: *Devices) void {
    @memset(&dev.screen, .{0} ** c8.display.HEIGHT);
}

fn jump(addr: Addr, dev: *Devices) void {
    dev.pc.addr = addr;
}

test "execute jump instruction" {
    var dev: Devices = .{};

    dev.ram[c8.memory.PROGRAM_START] = 0x12;
    dev.ram[c8.memory.PROGRAM_START + 1] = 0x03;
    dev.ram[0x203] = 0x12;
    dev.ram[0x204] = 0x06;
    dev.ram[0x206] = 0xab;
    dev.ram[0x207] = 0xcd;

    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    const inst = try dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
}

fn call(addr: Addr, dev: *Devices) void {
    dev.stack.push(dev.pc.addr) catch @panic(fmt.comptimePrint("stackoverflow. Stack size set to {d}\n", .{Config.stack_size}));
    dev.pc.addr = addr;
}

test "execute call instruction" {
    var dev: Devices = .{};

    dev.ram[c8.memory.PROGRAM_START] = 0x22;
    dev.ram[c8.memory.PROGRAM_START + 1] = 0x05;
    dev.ram[0x205] = 0x22;
    dev.ram[0x206] = 0x08;
    dev.ram[0x208] = 0xab;
    dev.ram[0x209] = 0xcd;

    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    const inst = try dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
    try testing.expectEqual(0x207, dev.stack.pop() catch @panic("trying to pop empty stack\n"));
    try testing.expectEqual(0x202, dev.stack.pop() catch @panic("trying to pop empty stack\n"));
}

fn ret(dev: *Devices) void {
    dev.pc.addr = dev.stack.pop() catch @panic("trying to pop out of empty stack");
}

test "execute ret instruction" {
    var dev: Devices = .{};
    dev.ram[c8.memory.PROGRAM_START] = 0x22;
    dev.ram[c8.memory.PROGRAM_START + 1] = 0x05;
    dev.ram[0x205] = 0x00;
    dev.ram[0x206] = 0xee;
    dev.ram[0x202] = 0xab;
    dev.ram[0x203] = 0xcd;

    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    const inst = try dev.pc.fetch(&dev.ram);
    try testing.expectEqual(0xabcd, @as(u16, @bitCast(inst)));
}

fn setX(dest_reg: u4, value: u8, dev: *Devices) void {
    dev.reg.v[dest_reg] = value;
}

test "execute set instruction" {
    var dev: Devices = .{};
    dev.ram[c8.memory.PROGRAM_START] = 0x64;
    dev.ram[c8.memory.PROGRAM_START + 1] = 0x33;
    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0x33, dev.reg.v[4]);
}

fn addX(dest_reg: u4, value: u8, dev: *Devices) void {
    dev.reg.v[dest_reg] +%= value;
}

test "execute add instruction" {
    var dev: Devices = .{};
    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0x65;
    dev.ram[dev.pc.addr + 1] = 0x33;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    dev.ram[dev.pc.addr] = 0x75;
    dev.ram[dev.pc.addr + 1] = 0x33;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0x66, dev.reg.v[5]);

    dev.ram[dev.pc.addr] = 0x75;
    dev.ram[dev.pc.addr + 1] = 0xff;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0xff, dev.reg.v[5]);
}

fn setI(value: Addr, dev: *Devices) void {
    dev.reg.i = value;
}

test "execute setI instruction" {
    var dev: Devices = .{};
    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0xa2;
    dev.ram[dev.pc.addr + 1] = 0x00;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0x200, dev.reg.i);

    dev.ram[dev.pc.addr] = 0xa2;
    dev.ram[dev.pc.addr + 1] = 0x50;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0x250, dev.reg.i);

    dev.ram[dev.pc.addr] = 0xaf;
    dev.ram[dev.pc.addr + 1] = 0xff;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0xfff, dev.reg.i);
}

fn displayI(reg_x: u4, reg_y: u4, rows: u4, dev: *Devices) void {
    var pos_x: usize = dev.reg.v[reg_x] % c8.display.WIDTH;
    var pos_y: usize = dev.reg.v[reg_y] % c8.display.HEIGHT;
    dev.reg.v[0xf] = 0;

    for (0..rows) |row| {
        if (pos_y >= c8.display.HEIGHT) {
            break;
        }
        // TODO: Overflow check maybe
        const sprite_byte = dev.ram[dev.reg.i + row];
        log.debug("sprite = {b:0>8}", .{sprite_byte});
        var idx: i4 = 7;
        const pos_x_orig = pos_x;
        defer pos_x = pos_x_orig;
        while (idx >= 0) : (idx -= 1) {
            const pixel: u1 = @truncate(sprite_byte >> @intCast(idx));
            if (pos_x >= c8.display.WIDTH) {
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
    debug.assert(dev.pc.addr == c8.memory.PROGRAM_START);
    dev.ram[dev.pc.addr] = 0xd0;
    dev.ram[dev.pc.addr + 1] = 0x11;
    dev.reg.v[0] = 1;
    dev.reg.v[1] = 16;
    dev.reg.i = 0x250;
    dev.ram[dev.reg.i] = 0b1111_1111;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);
    try testing.expectEqual(0, dev.reg.v[0xf]);

    var actual1: [8]u1 = undefined;
    var actual2: [8]u1 = undefined;
    var actual3: [8]u1 = undefined;

    for (0..8) |idx| {
        actual1[idx] = dev.screen[dev.reg.v[0] + idx][dev.reg.v[1]];
    }

    try testing.expectEqual(1, dev.reg.v[0]);
    try testing.expectEqual(16, dev.reg.v[1]);
    try testing.expectEqual(0, dev.reg.v[0xf]);
    try testing.expectEqualSlices(u1, &[_]u1{1} ** 8, &actual1);

    dev.ram[dev.pc.addr] = 0xd0;
    dev.ram[dev.pc.addr + 1] = 0x12;
    dev.ram[dev.reg.i] = 0b1000_1000;
    dev.ram[dev.reg.i + 1] = 0b0001_0001;
    (try dev.pc.fetch(&dev.ram)).decode(&dev);

    for (0..8) |idx| {
        actual2[idx] = dev.screen[dev.reg.v[0] + idx][dev.reg.v[1]];
    }

    for (0..8) |idx| {
        actual3[idx] = dev.screen[dev.reg.v[0] + idx][dev.reg.v[1] + 1];
    }

    try testing.expectEqual(1, dev.reg.v[0xf]);
    try testing.expectEqualSlices(u1, &[_]u1{ 0, 1, 1, 1, 0, 1, 1, 1 }, &actual2);
    try testing.expectEqualSlices(u1, &[_]u1{ 0, 0, 0, 1, 0, 0, 0, 1 }, &actual3);
}

fn skipEqX(reg_x: u4, compare: u8, dev: *Devices) void {
    if (dev.reg.v[reg_x] == compare) {
        dev.pc.addr +|= 2;
        return;
    } else {
        return;
    }
}

fn skipNotEqX(reg_x: u4, compare: u8, dev: *Devices) void {
    if (dev.reg.v[reg_x] == compare) {
        return;
    } else {
        dev.pc.addr +|= 2;
        return;
    }
}

fn skipEqXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    if (dev.reg.v[reg_x] == dev.reg.v[reg_y]) {
        dev.pc.addr +|= 2;
        return;
    } else {
        return;
    }
}

fn skipNotEqXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    if (dev.reg.v[reg_x] == dev.reg.v[reg_y]) {
        return;
    } else {
        dev.pc.addr +|= 2;
        return;
    }
}

fn setXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    dev.reg.v[reg_x] = dev.reg.v[reg_y];
}

fn orXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    dev.reg.v[reg_x] |= dev.reg.v[reg_y];
}

fn andXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    dev.reg.v[reg_x] &= dev.reg.v[reg_y];
}

fn xorXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    dev.reg.v[reg_x] ^= dev.reg.v[reg_y];
}

fn addXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    const sum, const carry = @addWithOverflow(dev.reg.v[reg_x], dev.reg.v[reg_y]);
    dev.reg.v[reg_x] = sum;
    dev.reg.v[0xf] = carry;
}

fn subXY(reg_x: u4, reg_y: u4, dev: *Devices) void {
    const res, const carry = @subWithOverflow(dev.reg.v[reg_x], dev.reg.v[reg_y]);
    dev.reg.v[reg_x] = res;
    dev.reg.v[0xf] = ~carry;
}

fn subYX(reg_x: u4, reg_y: u4, dev: *Devices) void {
    const res, const carry = @subWithOverflow(dev.reg.v[reg_y], dev.reg.v[reg_x]);
    dev.reg.v[reg_x] = res;
    dev.reg.v[0xf] = ~carry;
}

fn shrXY(reg_x: u4, reg_y: u4, dev: *Devices, orig: bool) void {
    dev.reg.v[reg_x] = if (orig) dev.reg.v[reg_y] else dev.reg.v[reg_x];
    const least_bit: u1 = @truncate(0 & dev.reg.v[reg_x]);
    dev.reg.v[reg_x] >>= 1;
    dev.reg.v[0xf] = least_bit;
}

fn shlXY(reg_x: u4, reg_y: u4, dev: *Devices, orig: bool) void {
    dev.reg.v[reg_x] = if (orig) dev.reg.v[reg_y] else dev.reg.v[reg_x];
    const most_bit: u1 = @truncate(dev.reg.v[reg_x] >> 7);
    dev.reg.v[reg_x] <<= 1;
    dev.reg.v[0xf] = most_bit;
}

fn memStore(reg_x: u4, dev: *Devices, orig: bool) void {
    const to: u8 = reg_x;
    @memcpy(dev.ram[dev.reg.i .. dev.reg.i + to + 1], dev.reg.v[0 .. to + 1]);
    if (orig) {
        dev.reg.i += reg_x + 1;
    }
}

fn memLoad(reg_x: u4, dev: *Devices, orig: bool) void {
    const to: u8 = reg_x;
    @memcpy(dev.reg.v[0 .. to + 1], dev.ram[dev.reg.i .. dev.reg.i + to + 1]);
    if (orig) {
        dev.reg.i += reg_x + 1;
    }
}

fn bcdc(reg_x: u4, dev: *Devices) void {
    dev.ram[dev.reg.i] = @divTrunc(dev.reg.v[reg_x], 100);
    dev.ram[dev.reg.i + 1] = @divTrunc(dev.reg.v[reg_x], 10) % 10;
    dev.ram[dev.reg.i + 2] = dev.reg.v[reg_x] % 10;
}

fn addI(reg_x: u4, dev: *Devices, set_overflow_flag: bool) void {
    const sum, const carry = @addWithOverflow(@as(u12, dev.reg.v[reg_x]), dev.reg.i);
    dev.reg.v[0xf] = if (set_overflow_flag) carry else dev.reg.v[0xf];
    dev.reg.i = sum;
}
