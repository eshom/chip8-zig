const std = @import("std");
const fs = std.fs;
const testing = std.testing;
const debug = std.debug;
const log = std.log;

const c8 = @import("chip8.zig");

pub const Rom = struct {
    bytes: []const u8,

    // There is no way for a ROM to be this large
    var buf: [c8.memory.TOTAL_MEM]u8 = undefined;

    pub fn read(rompath: []const u8) !Rom {
        const romfile = try fs.cwd().openFile(rompath, .{ .mode = .read_only });
        const read_n = try romfile.read(&Rom.buf);

        // TODO: I must be off by one or something, test this
        if (c8.memory.TOTAL_MEM - c8.memory.PROGRAM_START < read_n) {
            log.err("Rom size: {d}, but max allowed size is {d}", .{ read_n, c8.memory.TOTAL_MEM - c8.memory.PROGRAM_START });
            return c8.ProgramError.RomTooBig;
        }

        return .{
            .bytes = buf[0..read_n],
        };
    }

    // TODO: Add test for this
    pub fn load(self: *const Rom, memo: *c8.memory.Memory) void {
        const rom_section = memo[c8.memory.PROGRAM_START .. c8.memory.PROGRAM_START + self.bytes.len];

        var clobbered = false;
        for (rom_section) |byte| {
            if (byte != 0) {
                clobbered = true;
                break;
            }
        }
        debug.assert(!clobbered); // Section should be reserved for ROM or previous rom should be unloaded first

        @memcpy(rom_section, self.bytes);
    }

    pub fn unload(self: *const Rom, memo: *c8.memory.Memory) void {
        const rom_section = memo[c8.memory.PROGRAM_START .. c8.memory.PROGRAM_START + self.bytes.len];
        @memset(rom_section, 0);
    }
};

test "read rom" {
    // zig fmt: off
    const expected = [_]u8{
    0x00, 0xe0, 0xa2, 0x2a, 0x60, 0x0c, 0x61, 0x08, 0xd0, 0x1f, 0x70, 0x09,
    0xa2, 0x39, 0xd0, 0x1f, 0xa2, 0x48, 0x70, 0x08, 0xd0, 0x1f, 0x70, 0x04,
    0xa2, 0x57, 0xd0, 0x1f, 0x70, 0x08, 0xa2, 0x66, 0xd0, 0x1f, 0x70, 0x08,
    0xa2, 0x75, 0xd0, 0x1f, 0x12, 0x28, 0xff, 0x00, 0xff, 0x00, 0x3c, 0x00,
    0x3c, 0x00, 0x3c, 0x00, 0x3c, 0x00, 0xff, 0x00, 0xff, 0xff, 0x00, 0xff,
    0x00, 0x38, 0x00, 0x3f, 0x00, 0x3f, 0x00, 0x38, 0x00, 0xff, 0x00, 0xff,
    0x80, 0x00, 0xe0, 0x00, 0xe0, 0x00, 0x80, 0x00, 0x80, 0x00, 0xe0, 0x00,
    0xe0, 0x00, 0x80, 0xf8, 0x00, 0xfc, 0x00, 0x3e, 0x00, 0x3f, 0x00, 0x3b,
    0x00, 0x39, 0x00, 0xf8, 0x00, 0xf8, 0x03, 0x00, 0x07, 0x00, 0x0f, 0x00,
    0xbf, 0x00, 0xfb, 0x00, 0xf3, 0x00, 0xe3, 0x00, 0x43, 0xe5, 0x05, 0xe2,
    0x00, 0x85, 0x07, 0x81, 0x01, 0x80, 0x02, 0x80, 0x07, 0xe1, 0x06, 0xe7,
    };
    // zig fmt: on

    const rom = try Rom.read("roms/2-ibm-logo-test.ch8");
    try std.testing.expectEqualSlices(u8, &expected, rom.bytes);
}

test "load and unload rom" {
    var dev: c8.Devices = c8.Devices.init();
    const expected = [_]u8{ 0x00, 0xe0, 0xa2, 0x2a, 0x60, 0x0c };
    var rom_bytes: @TypeOf(expected) = undefined;
    @memcpy(&rom_bytes, &expected);

    const rom = Rom{ .bytes = &rom_bytes };
    dev.ram[c8.memory.PROGRAM_START - 1] = 0xaa;
    dev.ram[rom_bytes.len] = 0xaa;
    rom.load(&dev.ram);
    try testing.expectEqual(0xaa, dev.ram[c8.memory.PROGRAM_START - 1]);
    try testing.expectEqual(0xaa, dev.ram[rom_bytes.len]);
    try testing.expectEqualSlices(u8, &expected, dev.ram[c8.memory.PROGRAM_START .. c8.memory.PROGRAM_START + rom.bytes.len]);
    rom.unload(&dev.ram);
    try testing.expectEqual(0xaa, dev.ram[c8.memory.PROGRAM_START - 1]);
    try testing.expectEqual(0xaa, dev.ram[rom_bytes.len]);
    try testing.expectEqualSlices(u8, &[_]u8{0} ** 6, dev.ram[c8.memory.PROGRAM_START .. c8.memory.PROGRAM_START + rom.bytes.len]);
}
