const std = @import("std");
const Io = std.Io;

const mc = @import("mc");
const Server = mc.Server.ManagedServer(Manager);
const Client = mc.Client.ManagedClient(Manager);
const World = mc.World.ManagedWorld(Manager);

const Manager = struct {
    default_world: World,
    gpa: std.mem.Allocator,

    pub fn onConfigureFinish(this: *Manager, server: *Server, client: *Client) !void {
        _ = server;
        try this.default_world.addClient(client, this.gpa);
        var data: [24]mc.packets.play.client.ChunkWithLight.PacketSection = undefined;
        for (0..data.len) |i| {
            data[i] = .{
                .block_count = 0,
                .fluid_count = 0,
                .block_states = .{ .single_valued = .{ .value = 0 } },
                .biomes = .{ .single_valued = .{ .value = 0 } },
            };
        }
        try client.teleportPos(0, 364, 0);

        // try client.sendPacket(mc.packets.play.client.PlayerInfoUpdate{
            // .uuid = client.uuid,
            // .actions = &.{
                // .{ .add_player = .{
                    // .name = "username",
                    // .properties = &.{}
                // } }
            // }
        // });

        try client.sendPacket(mc.packets.play.client.SetCenterChunk{
            .x = 0,
            .z = 0,
        });
        try client.sendPacket(mc.packets.play.client.GameEvent{
            .data = .start_waiting_for_level_chunks,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 0,
            .z = 0,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 1,
            .z = 0,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 0,
            .z = 1,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 1,
            .z = 1,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = -1,
            .z = 0,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 0,
            .z = -1,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = -1,
            .z = -1,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = 1,
            .z = -1,
            .data = &data,
        });
        try client.sendPacket(mc.packets.play.client.ChunkWithLight{
            .x = -1,
            .z = 1,
            .data = &data,
        });
    }
};

pub fn main(init: std.process.Init) !void {
    var manager = Manager{
        .default_world = try .init(),
        .gpa = init.gpa,
    };
    var server = try Server.init(init.gpa, init.io, &manager);
    defer server.deinit();
    try server.start(try .parse("0.0.0.0", 25565));
}