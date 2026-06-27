const std = @import("std");
const protocol = @import("root.zig");

pub fn read(comptime T: type, buffer: []T, reader: *std.Io.Reader) ![]T {
    const len = try protocol.VarInt.read(reader);
    if (len > buffer.len) return error.BufferOverflow;
    for (0..@intCast(len)) |i| {
        buffer[i] = try T.read(reader);
    }
    return buffer[0..@intCast(len)];
}