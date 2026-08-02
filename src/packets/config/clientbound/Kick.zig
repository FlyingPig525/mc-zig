const std = @import("std");
const protocol = @import("../../../root.zig").protocol;

const Kick = @This();

pub const id = 0x02;

message: []const u8,

pub fn write(this: Kick, writer: *std.Io.Writer) !void {
    try protocol.String.write(this.message, writer);
}