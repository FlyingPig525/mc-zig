const packets = @import("packets");
const std = @import("std");
const protocol = @import("protocol");
const data = @import("data");

const ChunkWithLight = packets.play.client.ChunkWithLight;

const Chunk = @This();

x: i32,
y: i32,
sections: []const Section,

pub fn init(alloc: std.mem.Allocator, x: i32, y: i32, section_count: u16) !Chunk {
    return .{
        .x = x,
        .y = y,
        .sections = try alloc.alloc(Section, section_count),
    };
}

pub fn getSectionFromY(this: Chunk, y: i32) ?Section {
    if (y / 16 >= this.sections.len) return null;
    return this.sections[y / 16];
}

pub fn deinit(this: Chunk, alloc: std.mem.Allocator) void {
    alloc.free(this.sections);
}

// pub fn packet(this: Chunk, alloc: std.mem.Allocator) ChunkWithLight {
    // const sec_data = alloc.alloc(ChunkWithLight.PacketSection, this.sections.len);
//
// }

pub const Section = struct {
    block_count: u16,
    block_states: [16][16][16]data.Block,
    biomes: [64]data.Biome,

    pub fn toPacketSection(this: Section) ChunkWithLight.PacketSection {
        const biome_entries: [64]u32 = undefined;
        for (this.biomes, 0..) |biome, i| {
            biome_entries[i] = biome.id;
        }
        var block_count: i16 = 0;
        const block_entries: [4096]u32 = undefined;
        for (this.block_states, 0..) |z_layer, z| {
            for (z_layer, 0..) |y_layer, y| {
                for (y_layer, 0..) |block, x| {
                    block_entries[x + (16 * y) + (16 * z)] = block.state_id;
                    if (block.state_id != 0) block_count += 1;
                }
            }
        }
        return .{
            .block_count = block_count,
            .biomes = .{ .direct = .{ .entries = &biome_entries } },
            .block_states = .{ .direct = .{ .entries = &block_entries } },
        };
    }
};