const std = @import("std");
const protocol = @import("protocol");

const Handshake = @This();

pub const id = 0x00;

protocol_version: i32,
server_address: []const u8,
server_port: u16,
intent: Intent,

pub const Intent = enum(u8) {
    status = 1,
    login = 2,
    transfer = 3,
};

pub fn read(reader: *std.Io.Reader) !Handshake {
    const version = try protocol.VarInt.read(reader);
    const addr = try protocol.String.read(reader);
    const port = try reader.takeInt(u16, .big);
    const intent: Intent = @enumFromInt(try protocol.VarInt.read(reader));
    return .{
        .protocol_version = version,
        .server_address = addr,
        .server_port = port,
        .intent = intent,
    };
}