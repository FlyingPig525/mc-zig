pub const std = @import("std");

const Nbt = @This();

name: ?[]const u8,
root: []const Tag,
arena: ?std.heap.ArenaAllocator = null,

pub fn init(tags: []const Tag, name: ?[]const u8) Nbt {
    return .{
        .name = name,
        .root = tags,
    };
}

pub fn deinit(this: Nbt) void {
    if (this.arena) |arena| {
        arena.deinit();
    }
}

const ParseError = error { InvalidRootTag, UnexpectedEnd, ReadFailed, EndOfStream, OutOfMemory };

/// Parses an NBT structure from the a compound.
pub fn parse(reader: *std.Io.Reader, alloc: std.mem.Allocator, named: bool) ParseError!Nbt {
    const root_id: TagType = @enumFromInt(try reader.takeByte());
    if (root_id != TagType.compound) {
        return error.InvalidRootTag;
    }
    var arena = std.heap.ArenaAllocator.init(alloc);
    var name: ?[]const u8 = null;
    if (named) {
        const len = try reader.takeInt(u16, .big);
        name = try reader.take(len);
    }

    var list = std.ArrayList(Tag).empty;
    while (try parseInner(reader, arena.allocator(), true)) |tag| {
        try list.append(arena.allocator(), tag);
    }
    return .{
        .name = name,
        .root = try list.toOwnedSlice(arena.allocator()),
        .arena = arena,
    };
}

/// Returns null on Tag.end, allowing this to be placed in a while loop
///
/// Allocators passed should be arena to allow for proper freeing of memory. `parse` should be used instead of `parseInner`
pub fn parseInner(reader: *std.Io.Reader, alloc: std.mem.Allocator, named: bool) ParseError!?Tag {
    const b = try reader.takeByte();
    const id: TagType = @enumFromInt(b);
    return parseType(reader, id, alloc, named);
}

pub fn parseType(reader: *std.Io.Reader, id: TagType, alloc: std.mem.Allocator, named: bool) ParseError!?Tag {
    if (id == .end) return null;
    var name: ?[]const u8 = null;
    if (named) {
        const len = try reader.takeInt(u16, .big);
        name = try reader.take(len);
    }
    switch (id) {
        .end => unreachable,
        .byte => {
            const v = try reader.takeByteSigned();
            return .{ .byte = .{
                .name = name,
                .value = v,
            } };
        },
        .short => {
            const v = try reader.takeInt(i16, .big);
            return .{ .short = .{
                .name = name,
                .value = v,
            }};
        },
        .int => {
            const v = try reader.takeInt(i32, .big);
            return .{ .int = .{
                .name = name,
                .value = v,
            }};
        },
        .long => {
            const v = try reader.takeInt(i64, .big);
            return .{ .long = .{
                .name = name,
                .value = v,
            }};
        },
        .float => {
            const v = try reader.takeInt(u32, .big);
            return .{ .float = .{
                .name = name,
                .value = @bitCast(v),
            }};
        },
        .double => {
            const v = try reader.takeInt(u64, .big);
            return .{ .double = .{
                .name = name,
                .value = @bitCast(v),
            }};
        },
        .byte_array => {
            const len = try reader.takeInt(i32, .big);
            const v = try reader.take(@intCast(len));
            return .{ .byte_array = .{
                .name = name,
                .value = @ptrCast(v),
            }};
        },
        .string => {
            const len = try reader.takeInt(u16, .big);
            const v = try reader.take(len);
            return .{ .string = .{
                .name = name,
                .value = v,
            }};
        },
        .list => {
            const list_type: TagType = @enumFromInt(try reader.takeByte());
            const len = try reader.takeInt(i32, .big);
            if (len <= 0) {
                return .{ .list = .{
                    .name = name,
                    .value = .{
                        .type = list_type,
                        .list = &.{},
                    },
                }};
            }
            var buf = try alloc.alloc(Tag, @intCast(len));
            for (0..buf.len) |i| {
                buf[i] = try parseType(reader, list_type, alloc, false) orelse return error.UnexpectedEnd;
            }
            return .{ .list = .{
                .name = name,
                .value = .{
                    .type = list_type,
                    .list = buf,
                },
            }};
        },
        .compound => {
            var list = std.ArrayList(Tag).empty;
            while (true) {
                const tag = parseInner(reader, alloc, true) catch |err| switch (err) {
                    else => return err,
                };
                if (tag == null) break;
                try list.append(alloc, tag.?);
            }
            return .{ .compound = .{
                .name = name,
                .value = try list.toOwnedSlice(alloc),
            }};
        },
        .int_array => {
            const len = try reader.takeInt(i32, .big);
            var buf: []i32 = @alignCast(@ptrCast(try reader.take(@intCast(len))));
            for (0..buf.len) |i| {
                buf[i] = @byteSwap(buf[i]);
            }
            return .{ .int_array = .{
                .name = name,
                .value = buf,
            }};
        },
        .long_array => {
            const len = try reader.takeInt(i32, .big);
            var buf: []i64 = @alignCast(@ptrCast(try reader.take(@intCast(len))));
            for (0..buf.len) |i| {
                buf[i] = @byteSwap(buf[i]);
            }
            return .{ .long_array = .{
                .name = name,
                .value = buf,
            }};
        },
        else => unreachable,
    }
}

pub const WriteError = error { WriteFailed };

pub fn write(this: Nbt, writer: *std.Io.Writer) WriteError!void {
    const comp = Tag{ .compound = .{ .name = this.name, .value = this.root } };
    try comp.write(writer, this.name != null);
}

pub fn dump(this: Nbt, writer: *std.Io.Writer) !void {
    try writer.print("Compound({?s})\n", .{ this.name });
    for (this.root) |tag| {
        try tag.dumpIndent(writer, 1);
    }
    if (this.root[this.root.len - 1] != .end) {
        try writer.print("End({?s})\n", .{ this.name });
    }
}

pub const TagType = enum(u8) {
    end = 0,
    byte,
    short,
    int,
    long,
    float,
    double,
    byte_array,
    string,
    list,
    compound,
    int_array,
    long_array,
    no_encode,
};

pub fn Named(comptime T: type) type {
    return struct {
        name: ?[]const u8,
        value: T,
    };
}

pub const List = struct {
    type: TagType,
    list: []Tag,
};

pub const Tag = union(TagType) {
    /// TAG_End is 0
    end,
    byte: Named(i8),
    short: Named(i16),
    int: Named(i32),
    long: Named(i64),
    float: Named(f32),
    double: Named(f64),
    /// Length prefixed (i32)
    byte_array: Named([]i8),
    /// length prefixed (u16)
    string: Named([]const u8),
    /// Prefixed with the `Tag` type it contains (enum tag u8), then length prefixed (i32). If length is 0 the type can be anything
    ///
    /// All array items are guaranteed to have null names.
    list: Named(List),
    compound: Named([]const Tag),
    /// Length prefixed (i32)
    int_array: Named([]const i32),
    /// Length prefixed (i32)
    long_array: Named([]const i64),
    /// An empty type that will not be encoded or dumped in written nbt
    no_encode,

    pub fn write(tag: Tag, writer: *std.Io.Writer, named: bool) WriteError!void {
        if (tag == .no_encode) return;
        try writer.writeByte(@intFromEnum(tag));
        try tag.writeNoType(writer, named);
    }

    pub fn writeNoType(tag: Tag, writer: *std.Io.Writer, named: bool) WriteError!void {
        if (tag == .no_encode) return;
        if (tag != .end and named) {
            switch (tag) {
                .end, .no_encode => unreachable,
                inline else => |t| {
                    if (t.name) |n| {
                        try writer.writeInt(u16, @intCast(n.len), .big);
                        try writer.writeAll(n);
                    } else {
                        try writer.writeAll(&.{ 0, 0 });
                    }
                }
            }
        }
        switch (tag) {
            .end => {},
            .byte => |b| {
                try writer.writeByte(@bitCast(b.value));
            },
            .short => |s| {
                try writer.writeInt(i16, s.value, .big);
            },
            .int => |i| {
                try writer.writeInt(i32, i.value, .big);
            },
            .long => |l| {
                try writer.writeInt(i64, l.value, .big);
            },
            .float => |f| {
                try writer.writeInt(i32, @bitCast(f.value), .big);
            },
            .double => |d| {
                try writer.writeInt(i64, @bitCast(d.value), .big);
            },
            .byte_array => |arr| {
                try writer.writeInt(i32, @intCast(arr.value.len), .big);
                try writer.writeAll(@ptrCast(arr.value));
            },
            .string => |s| {
                try writer.writeInt(u16, @intCast(s.value.len), .big);
                try writer.writeAll(s.value);
            },
            .list => |l| {
                try writer.writeByte(@intFromEnum(l.value.type));
                try writer.writeInt(i32, @intCast(l.value.list.len), .big);
                for (l.value.list) |t| {
                    try t.writeNoType(writer, false);
                }
            },
            .compound => |c| {
                for (c.value) |t| {
                    try t.write(writer, true);
                }
                if (c.value[c.value.len - 1] != .end) {
                    try writer.writeByte(0);
                }
            },
            .int_array => |arr| {
                try writer.writeInt(i32, @intCast(arr.value.len), .big);
                for (arr.value) |int| {
                    try writer.writeInt(i32, int, .big);
                }
            },
            .long_array => |arr| {
                try writer.writeInt(i32, @intCast(arr.value.len), .big);
                for (arr.value) |long| {
                    try writer.writeInt(i64, long, .big);
                }
            },
            else => unreachable,
        }
    }

    pub fn dump(this: Tag, writer: *std.Io.Writer) !void {
        if (this == .no_encode) return;
        try dumpIndent(this, writer, 0);
    }

    pub fn dumpIndent(this: Tag, writer: *std.Io.Writer, indent: u8) !void {
        if (this == .no_encode) return;
        for (0..indent) |_| {
            try writer.print("  ", .{});
        }
        switch (this) {
            .byte => {
                try writer.print("Byte({?s}) = {d}\n", .{ this.byte.name, this.byte.value });
            },
            .short => {
                try writer.print("Short({?s}) = {d}\n", .{ this.short.name, this.short.value });
            },
            .int => {
                try writer.print("Int({?s}) = {d}\n", .{ this.int.name, this.int.value });
            },
            .long => {
                try writer.print("Long({?s}) = {d}\n", .{ this.long.name, this.long.value });
            },
            .float => {
                try writer.print("Float({?s}) = {d}\n", .{ this.float.name, this.float.value });
            },
            .double => {
                try writer.print("Double({?s}) = {d}\n", .{ this.double.name, this.double.value });
            },
            .byte_array => {
                try writer.print("ByteArray({?s}) = {any}\n", .{ this.byte_array.name, this.byte_array.value });
            },
            .string => {
                try writer.print("String({?s}) = {s}\n", .{ this.string.name, this.string.value });
            },
            .list => {
                try writer.print("List({?s}) = {s}\n", .{ this.list.name, @tagName(this.list.value.type) });
                for (this.list.value.list) |tag| {
                    try tag.dumpIndent(writer, indent + 1);
                }
            },
            .compound => {
                try writer.print("Compound({?s})\n", .{ this.compound.name });
                for (this.compound.value) |tag| {
                    try tag.dumpIndent(writer, indent + 1);
                }
                for (0..indent) |_| {
                    try writer.print("  ", .{});
                }
                if (this.compound.value[this.compound.value.len - 1] != .end) {
                    try writer.print("End({s})\n", .{ this.compound.name orelse "" });
                }
            },
            .int_array => {
                try writer.print("IntArray({?s}) = {any}\n", .{ this.int_array.name, this.int_array.value });
            },
            .long_array => {
                try writer.print("LongArray({?s}) = {any}\n", .{ this.long_array.name, this.long_array.value });
            },
            .end => {
                try writer.print("End\n", .{});
            },
            else => unreachable,
        }
    }
};

test "parse bigtest.nbt" {
    const file = @embedFile("testing/bigtest.nbt");
    const buf: []u8 = try std.testing.allocator.alloc(u8, file.len);
    defer std.testing.allocator.free(buf);
    @memcpy(buf, file);

    var reader = std.Io.Reader.fixed(buf);
    var nbt = try Nbt.parse(&reader, std.testing.allocator, true);
    defer nbt.deinit();

    const new_buf = try std.testing.allocator.alloc(u8, file.len);
    defer std.testing.allocator.free(new_buf);

    var writer = std.Io.Writer.fixed(new_buf);
    try nbt.write(&writer);
    try std.testing.expectEqualSlices(u8, buf, writer.buffered());
}

test "parse hello_world.nbt" {
    const file = @embedFile("testing/hello_world.nbt");
    const buf: []u8 = try std.testing.allocator.alloc(u8, file.len);
    defer std.testing.allocator.free(buf);
    @memcpy(buf, file);

    var reader = std.Io.Reader.fixed(buf);
    var nbt = try Nbt.parse(&reader, std.testing.allocator, true);
    defer nbt.deinit();

    const new_buf = try std.testing.allocator.alloc(u8, file.len);
    defer std.testing.allocator.free(new_buf);

    var writer = std.Io.Writer.fixed(new_buf);
    try nbt.write(&writer);
    try std.testing.expectEqualSlices(u8, buf, writer.buffered());
}