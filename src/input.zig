const std = @import("std");
const rl = @import("raylib.zig").raylib;

pub const pollInputEvents = rl.PollInputEvents;
pub const getKeyPressed = rl.GetKeyPressed;

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
