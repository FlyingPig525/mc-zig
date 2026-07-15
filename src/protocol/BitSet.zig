const std = @import("std");
const VarInt = @import("VarInt.zig");

pub fn write(bits: []const u1, writer: *std.Io.Writer) !void {
    try VarInt.write(@intCast(bits.len), writer);
    for (0..(bits.len/64)+1) |i| {
        var value: u64 = 0;
        for (bits[(i) * 64..@min((i + 1) * 64, bits.len)], 0..) |bit_value, bit_index| {
            value |= @as(u64, @intCast(bit_value)) << @intCast(bit_index);
        }
        try writer.writeInt(u64, value, .big);
    }
}