const ManagedClient = @import("Client.zig").ManagedClient;
const Chunk = @import("Chunk.zig");
const packets = @import("packets");
const std = @import("std");
const data = @import("data");
pub fn ManagedWorld(comptime Manager: type) type {
    return struct {
        const World = @This();
        const Client = ManagedClient(Manager);

        clients: std.ArrayList(*Client),
        chunks: data.TwoDimensionalList(Chunk),

        pub fn init() !World {
            return .{
                .clients = .empty,
                .chunks = .empty,
            };
        }

        pub fn setChunk(this: *World, alloc: std.mem.Allocator, x: usize, y: usize, chunk: Chunk) !void {
            try this.chunks.set(alloc, x, y, chunk);
        }

        pub fn addClient(this: *World, client: *Client, alloc: std.mem.Allocator) !void {
            try this.clients.append(alloc, client);
            try client.sendPacket(packets.play.client.Login{
                .player_id = client.id,
                .dimension_names = &.{
                    "minecraft:overworld",
                },
                .game_mode = .creative,
                .dimension_name = "minecraft:overworld",
                .dimension_id = 0,
            });
        }
    };
}
