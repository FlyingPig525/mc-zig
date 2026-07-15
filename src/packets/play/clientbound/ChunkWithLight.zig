const std = @import("std");
const protocol = @import("protocol");
const d = @import("data");

pub const id = 0x2c;
const ChunkWithLight = @This();

x: i32,
z: i32,
heightmap: ?HeightMap = null,
data: []const PacketSection,

pub fn write(this: ChunkWithLight, writer: *std.Io.Writer) !void {
    try writer.writeInt(i32, this.x, .big);
    try writer.writeInt(i32, this.z, .big);
    if (this.heightmap) |heightmap| {
        _ = heightmap;
    } else {
        try protocol.VarInt.write(0, writer);
    }
    var buf: [protocol.max_packet_length]u8 = undefined;
    var temp_writer = std.Io.Writer.fixed(&buf);
    for (this.data) |sec| {
        try sec.write(&temp_writer);
    }
    const written = temp_writer.buffered();
    try protocol.VarInt.write(@intCast(written.len), writer);
    try writer.writeAll(written);
    try protocol.VarInt.write(0, writer);
    const set_len = (this.data.len + 2) / 64;
    for (0..4) |_| {
        try protocol.VarInt.write(@intCast(set_len), writer);
        for (0..set_len) |_| {
            try writer.writeInt(u64, 0, .big);
        }
    }
    try protocol.VarInt.write(0, writer);
    try protocol.VarInt.write(0, writer);
}

// TODO: HEIGHTMAPS
pub const HeightMap = struct {

};

pub const PacketSection = struct {
    block_count: i16,
    fluid_count: i16,
    block_states: protocol.palette.PalettedContainer,
    biomes: protocol.palette.PalettedContainer,

    pub fn write(this: PacketSection, writer: *std.Io.Writer) !void {
        try writer.writeInt(i16, this.block_count, .big);
        try writer.writeInt(i16, this.fluid_count, .big);
        try this.block_states.write(writer);
        try this.biomes.write(writer);
    }
};