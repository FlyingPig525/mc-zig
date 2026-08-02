const std = @import("std");

pub fn TwoDimensionalMap(comptime K: type, comptime V: type) type {
    return struct {
        const Map = @This();

        const InnerMap = std.array_hash_map.Auto(K, V);
        const OuterMap = std.array_hash_map.Auto(K, InnerMap);

        maps: OuterMap,

        pub const empty: Map = .{
            .maps = .empty,
        };

        pub fn deinit(this: *Map, alloc: std.mem.Allocator) void {
            var iter = this.maps.iterator();
            while (iter.next()) |entry| {
                entry.value_ptr.deinit(alloc);
            }
            this.maps.deinit(alloc);
        }

        pub fn get(this: Map, x: K, y: K) ?*V {
            return (this.maps.get(x) orelse return null).getPtr(y);
        }

        pub fn set(this: *Map, alloc: std.mem.Allocator, x: K, y: K, item: V) !void {
            const map = this.maps.getPtr(x);
            if (map == null) {
                var new_inner = InnerMap.empty;
                try new_inner.put(alloc, y, item);
                try this.maps.put(alloc, x, new_inner);
                return;
            }
            try map.?.put(alloc, y, item);
        }
    };
}

