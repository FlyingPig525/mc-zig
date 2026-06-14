const std = @import("std");
const protocol = @import("root.zig");

pub fn read(reader: *std.Io.Reader) ![]u8 {
    const len = try protocol.VarInt.read(reader);
    return try reader.take(@intCast(len));
}

pub fn write(value: []const u8, writer: *std.Io.Writer) !void {
    try protocol.VarInt.write(@intCast(value.len), writer);
    try writer.writeAll(value);
}