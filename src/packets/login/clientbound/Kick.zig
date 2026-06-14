const std = @import("std");

const Kick = @This();

pub const id = 0x00;

message: []const u8,

pub fn write(this: Kick, writer: *std.Io.Writer) !void {
    try writer.writeAll(this.message);
}