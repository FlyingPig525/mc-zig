const std = @import("std");
const Nbt = @import("nbt").Nbt;
const protocol = @import("../root.zig").protocol;

const Entry = @This();

name: []const u8,
nbt: ?Nbt,

pub fn init(name: []const u8, nbt: ?Nbt) !Entry {
    return .{
        .name = name,
        .nbt = nbt,
    };
}

pub fn deinit(this: Entry, alloc: std.mem.Allocator) void {
    alloc.free(this.name);
    if (this.nbt != null) {
        this.nbt.?.deinit();
    }
}

pub fn read(reader: *std.Io.Reader) !Entry {
    const name = try protocol.String.read(reader);
    const b = try protocol.Boolean.read(reader);
    if (b) {
        var buf: [protocol.max_packet_length]u8 = undefined;
        var alloc = std.heap.FixedBufferAllocator.init(&buf);
        const nbt = try Nbt.parse(reader, alloc.allocator(), false);
        return .{
            .name = name,
            .nbt = nbt,
        };
    }
    return .{
        .name = name,
        .nbt = null,
    };
}