const std = @import("std");
const data = @import("../root.zig");

const Block = @This();

pub const blocks = @import("blocks.zig");

material: data.Material,
properties: Properties,
vtable: VTable,

pub fn clone(this: Block, alloc: std.mem.Allocator) !Block {
    return .{
        .material = this.material,
        .vtable = this.vtable,
        .properties = try this.properties.clone(alloc)
    };
}

pub fn state(this: Block) !u32 {
    return try this.vtable.state(this);
}

pub const VTable = struct {
    state: *const fn (block: Block) anyerror!u32,
};

pub fn deinit(this: *Block) void {
    this.properties.deinit();
}

pub const Properties = struct {
    backing_map: std.BufMap,

    pub fn init(alloc: std.mem.Allocator) !Properties {
        return .{
            .backing_map = .init(alloc)
        };
    }

    pub fn clone(this: Properties, alloc: std.mem.Allocator) !Properties {
        var new_map = std.BufMap.init(alloc);
        errdefer new_map.deinit();
        var iter = this.backing_map.iterator();
        while (iter.next()) |e| {
            try new_map.put(e.key_ptr.*, e.value_ptr.*);
        }
        return .{
            .backing_map = new_map,
        };
    }

    pub fn deinit(this: *Properties) void {
        this.backing_map.deinit();
    }

    pub fn set(this: *Properties, k: []const u8, v: []const u8) !void {
        try this.backing_map.put(k, v);
    }

    pub fn get(this: Properties, k: []const u8) ?[]const u8 {
        return this.backing_map.get(k);
    }

    pub const FromError = error { InvalidPropertyValue };
    pub fn getProp(this: Properties, comptime Type: type, k: []const u8) FromError!?Type {
        const prop = this.get(k) orelse return null;
        return try Type.from(prop);
    }

    fn EnumIterator(comptime Enum: type) type {
        comptime if (@typeInfo(Enum) != .@"enum") @compileError("Only enums can be iterated");

        return struct {
            curr: u16 = 0,

            pub fn next(this: *@This()) ?Enum {
                const tags = std.meta.tags(Enum);
                if (tags.len <= this.curr) return null;
                this.curr += 1;
                return tags[this.curr - 1];
            }
        };
    }

    pub const Direction = enum {
        north,
        south,
        east,
        west,

        pub fn value(this: @This()) []const u8 {
            return @tagName(this);
        }
        pub fn from(str: []const u8) FromError!@This() {
            return std.meta.stringToEnum(@This(), str) orelse FromError.InvalidPropertyValue;
        }
        pub fn iterator() EnumIterator(@This()) { return .{}; }
    };

    pub const Face = enum {
        floor,
        wall,
        ceiling,

        pub fn value(this: @This()) []const u8 {
            return @tagName(this);
        }
        pub fn from(str: []const u8) FromError!@This() {
            return std.meta.stringToEnum(@This(), str) orelse FromError.InvalidPropertyValue;
        }
        pub fn iterator() EnumIterator(@This()) { return .{}; }
    };

    pub const Bool = enum {
        true,
        false,

        pub fn value(this: @This()) []const u8 {
            return @tagName(this);
        }
        pub fn from(str: []const u8) FromError!@This() {
            return std.meta.stringToEnum(@This(), str) orelse FromError.InvalidPropertyValue;
        }
        pub fn iterator() EnumIterator(@This()) { return .{}; }
    };
};

test {
    std.testing.refAllDecls(@This());
}