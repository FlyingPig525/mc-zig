const std = @import("std");
const protocol = @import("protocol");

const LoginStart = @This();

pub const id = 0x00;

name: []const u8,
uuid: u128,

pub fn read(reader: *std.Io.Reader) !LoginStart {
    const name = try protocol.String.read(reader);
    const uuid = try protocol.Uuid.read(reader);
    return .{
        .name = name,
        .uuid = uuid,
    };
}