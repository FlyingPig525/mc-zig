const std = @import("std");

const protocol = @import("protocol");
const VarInt = protocol.VarInt;

const Packet = @This();

id: i32,
data: []const u8,

pub fn read(reader: *std.Io.Reader) !Packet {
    const len: u32 = @intCast(try VarInt.read(reader));
    const id = try VarInt.readWithWidth(reader);
    const data = try reader.take(len - id.width);
    return .{
        .id = id.value,
        .data = data,
    };
}

pub fn into(this: Packet, comptime T: type) !T {
    if (this.id != T.id) return error.InvalidPacketId;
    var reader = std.Io.Reader.fixed(this.data);
    return try T.read(&reader);
}

pub fn write(writer: *std.Io.Writer, packet: anytype) !void {
    var temp_buf: [protocol.max_packet_length]u8 = undefined;
    var temp_writer = std.Io.Writer.fixed(&temp_buf);
    try VarInt.write(@TypeOf(packet).id, &temp_writer);
    try packet.write(&temp_writer);
    try VarInt.write(@intCast(temp_writer.end), writer);
    try writer.writeAll(temp_writer.buffered());
    try writer.flush();
}