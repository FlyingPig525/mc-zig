const std = @import("std");
const protocol = @import("protocol");

const Pack = @This();

namespace: []const u8,
id: []const u8,
version: []const u8,

pub fn write(this: Pack, writer: *std.Io.Writer) !void {
    try protocol.String.write(this.namespace, writer);
    try protocol.String.write(this.id, writer);
    try protocol.String.write(this.version, writer);
}

pub fn read(reader: *std.Io.Reader) !Pack {
    const n = try protocol.String.read(reader);
    const i = try protocol.String.read(reader);
    const v = try protocol.String.read(reader);
    return .{
        .namespace = n,
        .id = i,
        .version = v,
    };
}