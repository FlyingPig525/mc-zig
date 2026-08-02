const std = @import("std");
const protocol = @import("root.zig");

pub const PalettedContainer = union(enum) {
    single_valued: SingleValued,
    indirect: Indirect,
    direct: Direct,

    pub fn write(this: PalettedContainer, writer: *std.Io.Writer) !void {
        switch (this) {
            // unimplemented
            .single_valued => |single| {
                try single.write(writer);
            },
            .indirect => unreachable,
            .direct => |direct| {
                try direct.write(writer);
            }
        }
    }
};

pub const SingleValued = struct {
    value: u32,

    pub fn write(this: SingleValued, writer: *std.Io.Writer) !void {
        try writer.writeByte(0);
        try protocol.VarInt.write(@intCast(this.value), writer);
    }
};

pub const Indirect = struct {};

pub const Direct = struct {
    entries: []const u32,

    pub const bits_per_entry: u64 = 15;
    pub const entries_per_long = @divFloor(64, bits_per_entry);
    pub const entry_mask: u64 = 0b111111111111111;


    pub fn write(this: Direct, writer: *std.Io.Writer) !void {
        try writer.writeByte(bits_per_entry);
        // wiki implementation
        const num_longs = (this.entries.len + entries_per_long - 1) / entries_per_long;
        // std.log.debug("num: {d}", .{ num_longs });
        for (0..num_longs) |long_index| {
            var long: u64 = 0;
            for (0..entries_per_long) |i| {
                const entry_index = i + (long_index * entries_per_long);
                const entry = this.entries[entry_index];
                const bit_index = entry_index % entries_per_long * bits_per_entry;
                long &= ~(entry_mask << @intCast(bit_index)) & entry_mask;
                long |= @as(u64, @intCast(entry)) << @intCast(bit_index);
            }
            try writer.writeInt(u64, long, .big);
        }
    }
};