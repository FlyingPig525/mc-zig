const std = @import("std");
const data = @import("data");
const protocol = @import("protocol");

const KnownPacks = @This();
pub const id = 0x07;

packs: []const data.Pack,

pub fn read(reader: *std.Io.Reader) !KnownPacks {
    var buf: [32]data.Pack = undefined;
    const packs = try protocol.PrefixedArray.read(data.Pack, &buf, reader);
    return .{
        .packs = packs,
    };
}