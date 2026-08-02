const std = @import("std");
const protocol = @import("../../../root.zig").protocol;

pub const id = 0x5c;
const SetCenterChunk = @This();

x: i32,
z: i32,

pub fn write(this: SetCenterChunk, writer: *std.Io.Writer) !void {
    try protocol.VarInt.write(this.x, writer);
    try protocol.VarInt.write(this.z, writer);
}