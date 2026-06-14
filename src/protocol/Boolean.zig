const std = @import("std");

pub fn read(reader: *std.Io.Reader) !bool {
    const byte = try reader.takeByte();
    return byte == 0x01;
}

pub fn write(b: bool, writer: *std.Io.Writer) !void {
    try writer.writeByte(if (b) 0x01 else 0);
}