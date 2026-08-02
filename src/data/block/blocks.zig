const std = @import("std");
const data = @import("../root.zig");
const Block = @import("Block.zig");
// const parse = data.Identifier.parse;
fn parse(comptime id: []const u8) data.Material {
    comptime return .{ .identifier = data.Identifier.parse(id) catch unreachable };
}
pub const acacia_button = ButtonBlock(10569, parse(":acacia_button"));
pub const air = SingleValueBlock(0, parse(":air"));
pub const cobblestone = SingleValueBlock(14, parse(":cobblestone"));

pub fn SingleValueBlock(comptime id: u32, comptime mat: data.Material) type {
    return struct {
        pub const vtable: Block.VTable = .{
            .state = &@This().state,
        };

        pub fn state(_: Block) !u32 { return id; }
        pub fn block(alloc: std.mem.Allocator) Block {
            return .{
                .material = mat,
                .vtable = vtable,
                .properties = try .init(alloc),
            };
        }
    };
}

pub fn ButtonBlock(comptime start_id: u32, comptime mat: data.Material) type {
    return struct {
        pub const vtable: Block.VTable = .{
            .state = &@This().state,
        };

        pub fn block(alloc: std.mem.Allocator) Block {
            return .{
                .material = mat,
                .vtable = vtable,
                .properties = try .init(alloc),
            };
        }

        pub fn state(this: Block) !u32 {
            const face = try this.properties.getProp(Block.Properties.Face, "face") orelse .floor;
            const facing = try this.properties.getProp(Block.Properties.Direction, "facing") orelse .north;
            const powered = try this.properties.getProp(Block.Properties.Bool, "powered") orelse .false;

            var id = start_id;
            var power_iter = Block.Properties.Bool.iterator();
            while (power_iter.next()) |p| {
                if (powered == p) break;
                id += 1;
            }
            var facing_iter = Block.Properties.Direction.iterator();
            while (facing_iter.next()) |f| {
                if (facing == f) break;
                id += 1;
            }
            var face_iter = Block.Properties.Face.iterator();
            while (face_iter.next()) |f| {
                if (f == face) break;
                id += 1;
            }
            return id;
        }
    };
}

test {
    std.testing.refAllDecls(@This());
}