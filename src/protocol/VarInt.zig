const std = @import("std");

const VarInt = @This();
pub const continue_bit: u8 = 0x80;
pub const segment_bits: u8 = 0x7f;

value: i32,
width: u8,

pub fn read(reader: *std.Io.Reader) !i32 {
    return (try readWithWidth(reader)).value;
}

pub fn readWithWidth(reader: *std.Io.Reader) !VarInt {
    var value: i32 = 0;
    var position: u5 = 0;

    var i: u8 = 0;
    while (true) {
        const byte = try reader.takeByte();
        if (i == 4 and (byte & continue_bit) == 1) return error.VarIntOverflow;
        const cast: i32 = @intCast(byte & segment_bits);
        value |= cast << position;
        if ((byte & continue_bit) == 0) break;
        position += 7;
        if (position >= 32) return error.VarIntOverflow;
        i += 1;
    }
    return .{
        .value = value,
        .width = i + 1,
    };
}

pub fn write(value: i32, writer: *std.Io.Writer) !void {
    // zig has no >>>= operator, so to emulate the behavior, value must be unsigned
    var u_value: u32 = @bitCast(value);
    while (true) {
        if ((u_value & ~@as(u32, @intCast(segment_bits))) == 0) {
            try writer.writeByte(@intCast(u_value));
            return;
        }
        try writer.writeByte(@intCast((u_value & segment_bits) | continue_bit));

        u_value = u_value >> 7;
    }
}