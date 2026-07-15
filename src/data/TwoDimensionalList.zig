const std = @import("std");

pub fn TwoDimensionalList(comptime T: type) type {
    return struct {
        const This = @This();

        array_lists: std.ArrayList(std.ArrayList(T)),

        pub const empty: This = .{
            .array_lists = .empty,
        };

        const GetErrors = error { XOutOfBounds, YOutOfBounds };

        pub fn get(this: This, x: usize, y: usize) GetErrors!T {
            if (x >= this.array_lists.items.len) return GetErrors.XOutOfBounds;
            const x_list = this.array_lists.items[x];
            if (y >= x_list.items.len) return GetErrors.YOutOfBounds;
            return try x_list.items[y];
        }

        pub fn set(this: *This, alloc: std.mem.Allocator, x: usize, y: usize, item: T) !void {
            if (x >= this.array_lists.items.len) {
                try this.array_lists.ensureTotalCapacity(alloc, x);
                this.array_lists.items[x] = try .initCapacity(alloc, y);
            }
            const x_list = &this.array_lists.items[x];
            try x_list.ensureTotalCapacity(alloc, y);
            x_list.items[y] = item;
        }
    };
}

