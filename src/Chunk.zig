const packets = @import("root.zig").packets;
const std = @import("std");
const protocol = @import("root.zig").protocol;
const data = @import("root.zig").data;

const assert = std.debug.assert;

const ChunkWithLight = packets.play.client.ChunkWithLight;

const Chunk = @This();

sections: []Section,

pub fn init(alloc: std.mem.Allocator, section_count: u16) !Chunk {
    const chunk = try initNoFill(alloc, section_count);
    for (chunk.sections) |*sec| {
        try sec.fillNoDeinit(data.Block.blocks.air.block(alloc), alloc);
        @memset(&sec.biomes, .{ .id = 0 });
    }
    return chunk;
}

pub fn initNoFill(alloc: std.mem.Allocator, section_count: u16) !Chunk {
    return .{
        .sections = try alloc.alloc(Section, section_count),
    };
}

pub fn getSectionFromY(this: Chunk, y: i32) ?Section {
    if (@divFloor(y, 16) >= this.sections.len) return null;
    return this.sections[@intCast(@divFloor(y, 16))];
}

/// Asserts that x and z are less than 16
pub fn setBlock(this: *Chunk, x: i32, y: i32, z: i32, block: data.Block) !void {
    assert(x < 16 and x >= 0);
    assert(z < 16 and z >= 0);

    const section_idx: usize = @intCast(@divFloor(y, 16));
    const section = &this.sections[section_idx];
    section.setBlock(@intCast(x), @intCast(@as(u32, @bitCast(y)) % 16), @intCast(z), block);
}

pub fn getBlock(this: Chunk, x: i32, y: i32, z: i32) *data.Block {
    assert(x < 16 and x >= 0);
    assert(z < 16 and z >= 0);
    return this.sections[@intCast(@divFloor(y, 16))].getBlock(@intCast(x), @intCast(@as(u32, @bitCast(y)) % 16), @intCast(z));
}

pub fn deinit(this: Chunk, alloc: std.mem.Allocator) void {
    alloc.free(this.sections);
}

pub fn getPacketData(this: Chunk, alloc: std.mem.Allocator) ![]ChunkWithLight.PacketSection {
    const arr = try alloc.alloc(ChunkWithLight.PacketSection, this.sections.len);
    for (this.sections, 0..) |sec, i| {
        arr[i] = try sec.toPacketSection(alloc);
    }
    return arr;
}

// pub fn packet(this: Chunk, alloc: std.mem.Allocator) ChunkWithLight {
    // const sec_data = alloc.alloc(ChunkWithLight.PacketSection, this.sections.len);
//
// }

pub const Section = struct {
    block_count: u16,
    blocks: [16][16][16]data.Block,
    biomes: [64]data.Biome,

    pub fn fill(this: *Section, block: data.Block, alloc: std.mem.Allocator) !void {
        for (0..16) |z| {
            for (0..16) |y| {
                for (0..16) |x| {
                    this.blocks[z][y][x].deinit();
                    this.blocks[z][y][x] = try block.clone(alloc);
                }
            }
        }
    }

    pub fn fillNoDeinit(this: *Section, block: data.Block, alloc: std.mem.Allocator) !void {
        for (0..16) |z| {
            for (0..16) |y| {
                for (0..16) |x| {
                    this.blocks[z][y][x] = try block.clone(alloc);
                }
            }
        }
    }

    pub fn deinit(this: Section) void {
        for (this.blocks) |z_layer| {
            for (z_layer) |y_layer| {
                for (y_layer) |block| {
                    block.deinit();
                }
            }
        }
    }

    pub fn setBlock(this: *Section, x: usize, y: usize, z: usize, block: data.Block) void {
        assert(x < 16);
        assert(y < 16);
        assert(z < 16);

        const prev = &this.blocks[z][y][x];
        prev.deinit();
        this.blocks[z][y][x] = block;
    }

    pub fn getBlock(this: *Section, x: usize, y: usize, z: usize) *data.Block {
        assert(x < 16);
        assert(y < 16);
        assert(z < 16);

        return &this.blocks[z][y][x];
    }

    pub fn toPacketSection(this: Section, alloc: std.mem.Allocator) !ChunkWithLight.PacketSection {
        var biome_entries = try alloc.alloc(u32, 64);
        for (this.biomes, 0..) |biome, i| {
            biome_entries[i] = biome.id;
            if (biome.id != 0) std.log.debug("AODJOAPWJD", .{});
        }
        var block_count: i16 = 0;
        var block_entries = try alloc.alloc(u32, 4096);
        for (this.blocks, 0..) |z_layer, z| {
            for (z_layer, 0..) |y_layer, y| {
                for (y_layer, 0..) |block, x| {
                    const state = try block.state();
                    block_entries[x + (16 * y) + (16 * z)] = state;
                    if (state != 0) block_count += 1;
                }
            }
        }
        return .{
            .block_count = block_count,
            .fluid_count = 0,
            .biomes = .{ .direct = .{ .entries = biome_entries } },
            .block_states = .{ .direct = .{ .entries = block_entries } },
        };
    }
};