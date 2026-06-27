const std = @import("std");
const protocol = @import("protocol");
const data = @import("data");

const KnownPacks = @This();
pub const id = 0x0e;

packs: []const data.Pack,

pub fn write(this: KnownPacks, writer: *std.Io.Writer) !void {
    try protocol.VarInt.write(@intCast(this.packs.len), writer);
    for (this.packs) |pack| {
        try pack.write(writer);
    }
}

pub const mc_core: KnownPacks = .{
    .packs = &.{
        .{ .namespace = "minecraft", .id = "core", .version = "1.21.10" },
    }
};