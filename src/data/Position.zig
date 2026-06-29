const std = @import("std");

pub const Position = packed struct {
    x: i26,
    z: i26,
    y: i12,

    pub fn write(this: Position, writer: *std.Io.Writer) !void {
        try writer.writeInt(u64, @bitCast(this), .big);
    }

    pub fn read(reader: *std.Io.Reader) !Position {
        return @bitCast(try reader.takeInt(u64, .big));
    }
};