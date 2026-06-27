const std = @import("std");
const reg = @import("registry");
const protocol = @import("protocol");

const RegistryData = @This();
pub const id = 0x07;

registry: reg.Registry,
with_nbt: bool = false,

pub fn write(this: RegistryData, writer: *std.Io.Writer) !void {
    try protocol.String.write(this.registry.name, writer);
    try protocol.VarInt.write(@intCast(this.registry.entries.len), writer);
    for (0..this.registry.entries.len) |i| {
        const entry = this.registry.entries[i];
        try protocol.String.write(entry.name, writer);
        try protocol.Boolean.write(this.with_nbt and entry.nbt != null, writer);
        if (entry.nbt != null and this.with_nbt) {
            std.debug.print("nbt\n", .{});
            try entry.nbt.?.write(writer);
        }
    }
}