const std = @import("std");
const memory = @import("memory.zig");
const font = @import("font.zig");
const heap = std.heap;
const debug = std.debug;

pub fn main() !void {
    @memset(&memory.ram, 0);
    var _fba = heap.FixedBufferAllocator.init(memory.ram[memory.PROGRAM_START..]);
    const fba = _fba.allocator();
    _ = fba; // autofix

    font.setFont(&memory.ram, &font.font_chars);

    memory.debugDumpMemory(&memory.ram, 16);
}
