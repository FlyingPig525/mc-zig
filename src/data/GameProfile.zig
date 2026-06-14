const protocol = @import("protocol");
const std = @import("std");

const GameProfile = @This();

uuid: u128,
username: []const u8,
properties: []const Property,

pub const Property = struct {
    key: []const u8,
    value: []const u8,
    signature: ?[]const u8,

    pub fn read(reader: *std.Io.Reader) !Property {
        const key = try protocol.String.read(reader);
        const value = try protocol.String.read(reader);
        const b = try protocol.Boolean.read(reader);
        if (!b) {
            return .{
                .key = key,
                .value = value,
                .signature = null,
            };
        } else {
            const sig = try protocol.String.read(reader);
            return .{
                .key = key,
                .value = value,
                .signature = sig,
            };
        }
    }

    pub fn write(this: Property, writer: *std.Io.Writer) !void {
        try protocol.String.write(this.key, writer);
        try protocol.String.write(this.value, writer);
        try protocol.Boolean.write(this.signature != null, writer);
        if (this.signature) |sig| {
            try protocol.String.write(sig, writer);
        }
    }
};

pub fn write(this: GameProfile, writer: *std.Io.Writer) !void {
    try protocol.Uuid.write(this.uuid, writer);
    try protocol.String.write(this.username, writer);
    try protocol.VarInt.write(@intCast(this.properties.len), writer);
    for (this.properties) |prop| {
        try prop.write(writer);
    }
}