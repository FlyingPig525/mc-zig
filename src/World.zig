const ManagedClient = @import("Client.zig").ManagedClient;
const Chunk = @import("Chunk.zig");
const root = @import("root.zig");
const packets = root.packets;
const std = @import("std");
const data = root.data;

pub fn ManagedWorld(comptime Manager: type) type {
    return struct {
        const World = @This();
        const Client = ManagedClient(Manager);

        clients: std.ArrayList(*Client),
        chunks: data.TwoDimensionalMap(i32, Chunk),
        dimension: data.Dimension,

        pub fn init() !World {
            return .{
                .clients = .empty,
                .chunks = .empty,
                .dimension = .{ .name = "minecraft:overworld" }
            };
        }

        pub fn sectionCount(this: World) u16 {
            return @intCast(@divFloor(this.dimension.height, 16));
        }

        // pub fn setChunk(this: *World, alloc: std.mem.Allocator, x: i32, z: i32, chunk: Chunk) !void {
            // try this.chunks.set(alloc, x, z, chunk);
        // }

        pub fn fillChunk(this: *World, alloc: std.mem.Allocator, chunk_x: i32, chunk_z: i32, block: data.Block) !void {
            const chunk_n = this.getChunk(chunk_x, chunk_z);
            if (chunk_n) |chunk| {
                for (chunk.sections) |*sec| {
                    try sec.fill(block, alloc);
                }
            } else {
                const chunk = try Chunk.initNoFill(alloc, this.sectionCount());
                for (chunk.sections) |*sec| {
                    try sec.fillNoDeinit(block, alloc);
                }
            }
        }

        pub fn generateChunk(this: *World, alloc: std.mem.Allocator, chunk_x: i32, chunk_z: i32) !*Chunk {
            const chunk = try Chunk.init(alloc, this.sectionCount());
            try this.chunks.set(alloc, chunk_x, chunk_z, chunk);
            return this.chunks.get(chunk_x, chunk_z) orelse unreachable;
        }

        pub fn getChunk(this: *World, chunk_x: i32, chunk_z: i32) ?*Chunk {
            return this.chunks.get(chunk_x, chunk_z);
        }

        pub fn getChunkGen(this: *World, alloc: std.mem.Allocator, chunkx: i32, chunkz: i32) !*Chunk {
            var chunk = this.chunks.get(chunkx, chunkz);
            if (chunk == null) {
                chunk = try this.generateChunk(alloc, chunkx, chunkz);
            }
            return chunk orelse unreachable;
        }

        pub fn setBlock(this: *World, alloc: std.mem.Allocator, x: i32, y: i32, z: i32, block: data.Block) !void {
            const chunk_x = @divFloor(x, 16);
            const chunk_z = @divFloor(z, 16);

            try (try this.getChunkGen(alloc, chunk_x, chunk_z)).setBlock(@intCast(@as(u32, @bitCast(x)) % 16), y, @intCast(@as(u32, @bitCast(z)) % 16), block);
        }

        pub fn getBlock(this: *World, alloc: std.mem.Allocator, x: i32, y: i32, z: i32) !*data.Block {
            const chunk_x = @divFloor(x, 16);
            const chunk_z = @divFloor(z, 16);
            const chunk = try this.getChunkGen(alloc, chunk_x, chunk_z);
            return chunk.getBlock(@rem(x, 16), y, @rem(z, 16));
        }

        pub fn addClient(this: *World, client: *Client, position: data.Position, alloc: std.mem.Allocator) !void {
            try this.clients.append(alloc, client);
            try client.sendPacket(packets.play.client.Login{
                .player_id = client.id,
                .dimension_names = &.{
                    this.dimension.name,
                },
                .game_mode = .creative,
                .dimension_name = this.dimension.name,
                .dimension_id = 0,
            });
            try client.teleportVerbose(position, 0, 0, 0, .abs);
            const chunk_x = position.chunkX();
            const chunk_z = position.chunkZ();
            try client.sendPacket(root.packets.play.client.GameEvent{
                .data = .start_waiting_for_level_chunks,
            });
            try client.sendPacket(root.packets.play.client.SetCenterChunk{
                .x = chunk_x,
                .z = chunk_z,
            });
            for (0..5) |x_off_u| {
                const x_off = @as(i32, @intCast(x_off_u)) - 2;
                for (0..5) |z_off_u| {
                    const z_off = @as(i32, @intCast(z_off_u)) - 2;
                    const x = chunk_x + x_off;
                    const z = chunk_z + z_off;
                    const chunk = try this.getChunkGen(alloc, x, z);
                    const chunk_data = try chunk.getPacketData(alloc);
                    std.log.debug("sending chunk {d} {d}", .{ x, z });
                    defer {
                        for (chunk_data) |sec| {
                            sec.deinit(alloc);
                        }
                        alloc.free(chunk_data);
                    }
                    try client.sendPacket(root.packets.play.client.ChunkWithLight{
                        .x = x,
                        .z = z,
                        .data = chunk_data,
                    });
                }
            }
        }

        const RemoveError = error { ClientNotFound };
        pub fn removeClient(this: *World, client: *Client) RemoveError!void {
            for (this.clients.items, 0..) |c, i| {
                if (c == client) {
                    _ = this.clients.swapRemove(i);
                    return;
                }
            }
            return RemoveError.ClientNotFound;
        }
    };
}
