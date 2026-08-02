const std = @import("std");
const data = @import("root").data;
const reg = @import("root").registry;

const Dimension =  @This();

name: []const u8,

has_skylight: bool = true,
has_ceiling: bool = false,
has_ender_dragon_fight: bool = false,
coordinate_scale: f64 = 1,
has_fixed_time: bool = false,
has_raids: bool = true,
bed_works: bool = true,
natural: bool = true,
piglin_safe: bool = true,
respawn_anchor_works: bool = false,
ultrawarm: bool = false,
ambient_light: f32 = 0,
min_y: i32 = -64,
height: i32 = 384,
monster_spawn_light_level: i32 = 7,
monster_spawn_block_light_limit: i32 = 0,
infiniburn: []const u8 = "#infiniburn_overworld",
skybox: []const u8 = "overworld",
cardinal_light: []const u8 = "default",
default_clock: []const u8 = "overworld",

// this is needed so the names arent stack allocated and survive past the call to `registry`
// const reg_name = "minecraft:dimension_type";
// const has_skylight_name = "has_skylight";
// const has_ceiling_name = "has_ceiling";
// const has_ender_dragon_fight_name = "has_ender_dragon_fight";
// const coordinate_scale_name = "coordinate_scale";
// const has_fixed_time_name = "has_fixed_time";
// const has_raids_name = "has_raids";
// const bed_works_name = "bed_works";
// const natural_name = "natural";
// const piglin_safe_name = "piglin_safe";
// const respawn_anchor_works_name = "respawn_anchor_works";
// const ultrawarm_name = "ultrawarm";
// const ambient_light_name = "ambient_light";
// const min_y_name = "min_y";
// const height_name = "height";
// monster_spawn_light_level: i32 = 7,
// monster_spawn_block_light_limit: i32 = 0,
// infiniburn: []const u8 = "#infiniburn_overworld",
// skybox: []const u8 = "overworld",
// cardinal_light: []const u8 = "default",
// default_clock: []const u8 = "overworld",

pub fn registry(this: Dimension, alloc: std.mem.Allocator) reg.Registry {
    return .{
        .name = "minecraft:dimension_type",
        .entries = &.{
            .{ .name = "minecraft:overworld", .nbt = .encodeStruct(Dimension, this, alloc, true) }
        },
    };
}