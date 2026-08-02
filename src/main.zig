const std = @import("std");
const Io = std.Io;

const mc = @import("mc");
const Server = mc.Server.ManagedServer(Manager);
const Client = mc.Client.ManagedClient(Manager);
const World = mc.World.ManagedWorld(Manager);

const blocks = mc.data.Block.blocks;
const event = mc.Event(Manager);

const Manager = struct {
    default_world: World,
    gpa: std.mem.Allocator,

    pub fn onConfigureFinish(this: *Manager, server: *Server, _: *Client, e: *event.ConfigurationFinish) !void {
        try this.default_world.setBlock(this.gpa, 0, 300, 0, blocks.acacia_button.block(this.gpa));
        std.log.debug("{d}", .{ try blocks.cobblestone.block(this.gpa).state() });
        const chunk = try this.default_world.getChunkGen(this.gpa, 1, 1);
        for (chunk.sections) |*sec| {
            try sec.fill(blocks.cobblestone.block(this.gpa), this.gpa);
        }
        try this.default_world.fillChunk(this.gpa, 1, 1, blocks.cobblestone.block(this.gpa));
        _ = server;
        e.world = &this.default_world;
        e.spawn_position = .{ .x = 0, .y = 301, .z = 0 };
        const blk = try this.default_world.getBlock(this.gpa, 0, 300, 0);
        std.log.info("y300 {d}", .{ try blk.state() });
        // try client.sendPacket(mc.packets.play.client.PlayerInfoUpdate{
            // .uuid = client.uuid,
            // .actions = &.{
                // .{ .add_player = .{
                    // .name = "username",
                    // .properties = &.{}
                // } }
            // }
        // });

        // try client.sendPacket(mc.packets.play.client.SetCenterChunk{
            // .x = 0,
            // .z = 0,
        // });
        // try client.sendPacket(mc.packets.play.client.GameEvent{
            // .data = .start_waiting_for_level_chunks,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 0,
        //     .z = 0,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 1,
        //     .z = 0,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 0,
        //     .z = 1,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 1,
        //     .z = 1,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = -1,
        //     .z = 0,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 0,
        //     .z = -1,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = -1,
        //     .z = -1,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = 1,
        //     .z = -1,
        //     .data = &data,
        // });
        // try client.sendPacket(mc.packets.play.client.ChunkWithLight{
        //     .x = -1,
        //     .z = 1,
        //     .data = &data,
        // });
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