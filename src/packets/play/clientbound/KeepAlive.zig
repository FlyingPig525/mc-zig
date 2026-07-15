const std = @import("std");

pub const id = 0x2b;
const KeepAlive = @This();

out_id: i64,

pub fn write(this: KeepAlive, writer: *std.Io.Writer) !void {
    try writer.writeInt(i64, this.out_id, .big);
}