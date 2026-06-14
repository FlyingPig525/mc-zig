const std = @import("std");


pub fn read(reader: *std.Io.Reader) !u128 {
    const significant = try reader.takeInt(u64, .big);
    const lower = try reader.takeInt(u64, .big);
    return (@as(u128, @intCast(significant)) << 64) + lower;
}

pub fn write(uuid: u128, writer: *std.Io.Writer) !void {
    try writer.writeInt(u64, @intCast((uuid & 0xFFFFFFFFFFFFFFFF0000000000000000) >> 64), .big);
    try writer.writeInt(u64, @truncate(uuid & 0xFFFFFFFFFFFFFFFF), .big);
}