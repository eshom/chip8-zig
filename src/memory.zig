const std = @import("std");
const testing = std.testing;
const debug = std.debug;

pub const RESERVED_INT_START = 0x000;
pub const RESERVED_INT_END = 0x1FF; // inclusive
pub const PROGRAM_START = 0x200;
pub const TOTAL_MEM = 4096;

pub var ram: [TOTAL_MEM]u8 = undefined;
pub var reg: Reg = .{};
pub var stack = Stack(100){};

fn Stack(size: comptime_int) type {
    return struct {
        items: [size]u12 = undefined,
        cur: isize = -1,

        const Self = @This();

        pub fn push(self: *Self, elem: u12) !void {
            if (self.cur + 1 >= size) {
                return error.OutOfBounds;
            }

            self.cur += 1;
            self.items[@intCast(self.cur)] = elem;
        }

        pub fn pop(self: *Self) !u12 {
            if (self.cur < 0) {
                return error.OutOfBounds;
            }

            const out = self.items[@intCast(self.cur)];
            self.cur -= 1;
            return out;
        }
    };
}

test "Stack" {
    var test_stack = Stack(3){};
    try testing.expectError(error.OutOfBounds, test_stack.pop());
    try test_stack.push(1);
    try test_stack.push(2);
    try test_stack.push(3);
    try testing.expectError(error.OutOfBounds, test_stack.push(4));
    try testing.expectEqualSlices(u12, &test_stack.items, &[3]u12{ 1, 2, 3 });
    try testing.expectEqual(3, test_stack.pop());
    try testing.expectEqual(2, test_stack.pop());
    try testing.expectEqual(1, test_stack.pop());
}

const Reg = struct {
    // General purpose registers
    v1: u8 = 0,
    v2: u8 = 0,
    v3: u8 = 0,
    v4: u8 = 0,
    v5: u8 = 0,
    v6: u8 = 0,
    v7: u8 = 0,
    v8: u8 = 0,
    v9: u8 = 0,
    va: u8 = 0,
    vb: u8 = 0,
    vc: u8 = 0,
    vd: u8 = 0,
    ve: u8 = 0,
    vf: u8 = 0, // Flag register
    i: u12 = 0, // Address register
};

test "Reg" {
    reg.v1 = 5;
    reg.v2 = 10;
    reg.i = 0xaaa;
    try testing.expectEqual(Reg{ .v1 = 5, .v2 = 10, .i = 0xaaa }, reg);
}

pub fn debugDumpMemory(memory: []const u8, bytes_per_line: u8) void {
    var idx: usize = 0;
    var bpair: [2]u8 = undefined;
    while (idx < memory.len) : (idx += 2) {
        bpair = .{ memory[idx], memory[idx + 1] };
        if (idx % bytes_per_line == 0) {
            debug.print("\n", .{});
            debug.print("0x{x:0>3}: ", .{idx});
        }
        std.debug.print("{x:0>2}{x:0>2} ", .{ bpair[0], bpair[1] });
    }
    std.debug.print("\n", .{});
}
