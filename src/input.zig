const std = @import("std");
const rl = @import("raylib.zig").rl;

pub const pollInputEvents = rl.PollInputEvents;
pub const isKeyDown = rl.IsKeyDown;
pub const isKeyReleased = rl.IsKeyReleased;
pub const isKeyUp = rl.IsKeyUp;

pub fn getKeyPressed() error{NoKey}!c_int {
    const key = rl.GetKeyPressed();
    if (key == 0) {
        return error.NoKey;
    }
    return key;
}

pub const keypad: [16]c_int = .{
    rl.KEY_X, // 0
    rl.KEY_ONE,
    rl.KEY_TWO,
    rl.KEY_THREE,
    rl.KEY_Q, // 4
    rl.KEY_W, // 5
    rl.KEY_E, // 6
    rl.KEY_A, // 7
    rl.KEY_S, // 8
    rl.KEY_D, // 9
    rl.KEY_Z, // a
    rl.KEY_C, // b
    rl.KEY_FOUR, // c
    rl.KEY_R, // d
    rl.KEY_F, // e
    rl.KEY_V, // f
};

pub const Keypad = enum(c_int) {
    one = rl.KEY_ONE,
    two = rl.KEY_TWO,
    three = rl.KEY_THREE,
    c = rl.KEY_FOUR,

    four = rl.KEY_Q,
    five = rl.KEY_W,
    six = rl.KEY_E,
    d = rl.KEY_R,

    seven = rl.KEY_A,
    eight = rl.KEY_S,
    nine = rl.KEY_D,
    e = rl.KEY_F,

    a = rl.KEY_Z,
    zero = rl.KEY_X,
    b = rl.KEY_C,
    f = rl.KEY_V,
};

pub const keymap = std.EnumMap(Keypad, u4).init(.{
    .zero = 0x0,
    .one = 0x1,
    .two = 0x2,
    .three = 0x3,
    .four = 0x4,
    .five = 0x5,
    .six = 0x6,
    .seven = 0x7,
    .eight = 0x8,
    .nine = 0x9,
    .a = 0xa,
    .b = 0xb,
    .c = 0xc,
    .d = 0xd,
    .e = 0xe,
    .f = 0xf,
});
