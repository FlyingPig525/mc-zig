const std = @import("std");

pub const id = 0x1b;
const KeepAlive = @This();

in_id: i64,

pub fn read(reader: *std.Io.Reader) !KeepAlive {
    return .{
        .in_id = try reader.takeInt(i64, .big),
    };
}