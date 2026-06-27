const std = @import("std");
const Entry = @import("Entry.zig");
const protocol = @import("protocol");
const data = @import("data");

const Registry = @This();

name: []const u8,
entries: []const Entry,

pub fn deinit(this: *Registry, alloc: std.mem.Allocator) void {
    for (0..this.entries.len) |i| {
        this.entries[i].deinit(alloc);
    }
}

// these are here until registry data actually gets parsed
pub const biome: Registry = .{
    .name = "minecraft:worldgen/biome",
    .entries = &.{
        .{ .name = "minecraft:plains", .nbt = null }
    },
};
pub const dimension: Registry = .{
    .name = "minecraft:dimension_type",
    .entries = &.{
        .{ .name = "minecraft:overworld", .nbt = .init(&.{
            .{ .byte = .{ .name = "has_skylight", .value = 0x01 } },
            .{ .byte = .{ .name = "has_ceiling", .value = 0x00 } },
            .{ .byte = .{ .name = "has_ender_dragon_fight", .value = 0x00 } },
            .{ .double = .{ .name = "coordinate_scale", .value = 1 } },
            .{ .byte = .{ .name = "has_fixed_time", .value = 0x00 } },
            .{ .float = .{ .name = "ambient_light", .value = 0 } },
            .{ .int = .{ .name = "min_y", .value = -64 } },
            .{ .int = .{ .name = "height", .value = 384 } },
            .{ .int = .{ .name = "logical_height", .value = 384 } },
            .{ .int = .{ .name = "monster_spawn_light_level", .value = 7 } },
            .{ .int = .{ .name = "monster_spawn_block_light_limit", .value = 0 } },
            .{ .string = .{ .name = "infiniburn", .value = "#infiniburn_overworld" } },
            .{ .string = .{ .name = "skybox", .value = "overworld" } },
            .{ .string = .{ .name = "cardinal_light", .value = "default" } },
            .{ .string = .{ .name = "default_clock", .value = "overworld" } },
        }, null) }
    },
};
pub const cat_variant: Registry = .{
    .name = "minecraft:cat_variant",
    .entries = &.{
        .{ .name = "minecraft:calico", .nbt = null },
        .{ .name = "minecraft:jellie", .nbt = null },
        .{ .name = "minecraft:black", .nbt = null },
        .{ .name = "minecraft:persian", .nbt = null },
        .{ .name = "minecraft:red", .nbt = null },
        .{ .name = "minecraft:siamese", .nbt = null },
        .{ .name = "minecraft:all_black", .nbt = null },
        .{ .name = "minecraft:british_shorthair", .nbt = null },
        .{ .name = "minecraft:white", .nbt = null },
        .{ .name = "minecraft:ragdoll", .nbt = null },
        .{ .name = "minecraft:tabby", .nbt = null },
    }
};
pub const chicken_variant: Registry = .{
    .name = "minecraft:chicken_variant",
    .entries = &.{
        .{ .name = "minecraft:warm", .nbt = null },
        .{ .name = "minecraft:cold", .nbt = null },
        .{ .name = "minecraft:temperate", .nbt = null },
    }
};
pub const cow_variant: Registry = .{
    .name = "minecraft:cow_variant",
    .entries = &.{
        .{ .name = "minecraft:warm", .nbt = null },
        .{ .name = "minecraft:cold", .nbt = null },
        .{ .name = "minecraft:temperate", .nbt = null },
    }
};
pub const frog_variant: Registry = .{
    .name = "minecraft:frog_variant",
    .entries = &.{
        .{ .name = "minecraft:warm", .nbt = null },
        .{ .name = "minecraft:cold", .nbt = null },
        .{ .name = "minecraft:temperate", .nbt = null },
    }
};
pub const pig_variant: Registry = .{
    .name = "minecraft:pig_variant",
    .entries = &.{
        .{ .name = "minecraft:warm", .nbt = null },
        .{ .name = "minecraft:cold", .nbt = null },
        .{ .name = "minecraft:temperate", .nbt = null },
    }
};
pub const wolf_variant: Registry = .{
    .name = "minecraft:wolf_variant",
    .entries = &.{
        .{ .name = "minecraft:black", .nbt = null },
        .{ .name = "minecraft:woods", .nbt = null },
        .{ .name = "minecraft:striped", .nbt = null },
        .{ .name = "minecraft:spotted", .nbt = null },
        .{ .name = "minecraft:snowy", .nbt = null },
        .{ .name = "minecraft:pale", .nbt = null },
        .{ .name = "minecraft:chestnut", .nbt = null },
        .{ .name = "minecraft:ashen", .nbt = null },
        .{ .name = "minecraft:rusty", .nbt = null },
    }
};
pub const wolf_sound_variant: Registry = .{
    .name = "minecraft:wolf_sound_variant",
    .entries = &.{
        .{ .name = "minecraft:angry", .nbt = null },
        .{ .name = "minecraft:classic", .nbt = null },
        .{ .name = "minecraft:grumpy", .nbt = null },
        .{ .name = "minecraft:big", .nbt = null },
        .{ .name = "minecraft:puglin", .nbt = null },
        .{ .name = "minecraft:cute", .nbt = null },
        .{ .name = "minecraft:sad", .nbt = null },
    }
};
pub const damage_type: Registry = .{
    .name = "minecraft:damage_type",
    .entries = &.{
        .{ .name = "minecraft:campfire", .nbt = null },
        .{ .name = "minecraft:falling_stalactite", .nbt = null },
        .{ .name = "minecraft:starve", .nbt = null },
        .{ .name = "minecraft:fly_into_wall", .nbt = null },
        .{ .name = "minecraft:cramming", .nbt = null },
        .{ .name = "minecraft:mob_attack_no_aggro", .nbt = null },
        .{ .name = "minecraft:drown", .nbt = null },
        .{ .name = "minecraft:wither", .nbt = null },
        .{ .name = "minecraft:sweet_berry_bush", .nbt = null },
        .{ .name = "minecraft:mob_attack", .nbt = null },
        .{ .name = "minecraft:generic_kill", .nbt = null },
        .{ .name = "minecraft:generic", .nbt = null },
        .{ .name = "minecraft:magic", .nbt = null },
        .{ .name = "minecraft:fireball", .nbt = null },
        .{ .name = "minecraft:spit", .nbt = null },
        .{ .name = "minecraft:on_fire", .nbt = null },
        .{ .name = "minecraft:bad_respawn_point", .nbt = null },
        .{ .name = "minecraft:cactus", .nbt = null },
        .{ .name = "minecraft:fireworks", .nbt = null },
        .{ .name = "minecraft:falling_anvil", .nbt = null },
        .{ .name = "minecraft:arrow", .nbt = null },
        .{ .name = "minecraft:hot_floor", .nbt = null },
        .{ .name = "minecraft:fall", .nbt = null },
        .{ .name = "minecraft:out_of_world", .nbt = null },
        .{ .name = "minecraft:thrown", .nbt = null },
        .{ .name = "minecraft:in_wall", .nbt = null },
        .{ .name = "minecraft:stalagmite", .nbt = null },
        .{ .name = "minecraft:player_attack", .nbt = null },
        .{ .name = "minecraft:outside_border", .nbt = null },
        .{ .name = "minecraft:falling_block", .nbt = null },
        .{ .name = "minecraft:lava", .nbt = null },
        .{ .name = "minecraft:indirect_magic", .nbt = null },
        .{ .name = "minecraft:ender_pearl", .nbt = null },
        .{ .name = "minecraft:wind_charge", .nbt = null },
        .{ .name = "minecraft:mob_projectile", .nbt = null },
        .{ .name = "minecraft:explosion", .nbt = null },
        .{ .name = "minecraft:wither_skull", .nbt = null },
        .{ .name = "minecraft:dragon_breath", .nbt = null },
        .{ .name = "minecraft:mace_smash", .nbt = null },
        .{ .name = "minecraft:dry_out", .nbt = null },
        .{ .name = "minecraft:thorns", .nbt = null },
        .{ .name = "minecraft:sting", .nbt = null },
        .{ .name = "minecraft:sonic_boom", .nbt = null },
        .{ .name = "minecraft:in_fire", .nbt = null },
        .{ .name = "minecraft:unattributed_fireball", .nbt = null },
        .{ .name = "minecraft:player_explosion", .nbt = null },
        .{ .name = "minecraft:trident", .nbt = null },
        .{ .name = "minecraft:freeze", .nbt = null },
        .{ .name = "minecraft:lightning_bolt", .nbt = null },
    }
};
pub const painting_variant: Registry = .{
    .name = "minecraft:painting_variant",
    .entries = &.{
        .{ .name = "minecraft:humble", .nbt = null },
        .{ .name = "minecraft:cavebird", .nbt = null },
        .{ .name = "minecraft:courbet", .nbt = null },
        .{ .name = "minecraft:sea", .nbt = null },
        .{ .name = "minecraft:wither", .nbt = null },
        .{ .name = "minecraft:burning_skull", .nbt = null },
        .{ .name = "minecraft:meditative", .nbt = null },
        .{ .name = "minecraft:prairie_ride", .nbt = null },
        .{ .name = "minecraft:fire", .nbt = null },
        .{ .name = "minecraft:wasteland", .nbt = null },
        .{ .name = "minecraft:skull_and_roses", .nbt = null },
        .{ .name = "minecraft:pigscene", .nbt = null },
        .{ .name = "minecraft:unpacked", .nbt = null },
        .{ .name = "minecraft:fern", .nbt = null },
        .{ .name = "minecraft:sunflowers", .nbt = null },
        .{ .name = "minecraft:fighters", .nbt = null },
        .{ .name = "minecraft:earth", .nbt = null },
        .{ .name = "minecraft:bust", .nbt = null },
        .{ .name = "minecraft:match", .nbt = null },
        .{ .name = "minecraft:cotan", .nbt = null },
        .{ .name = "minecraft:bouquet", .nbt = null },
        .{ .name = "minecraft:changing", .nbt = null },
        .{ .name = "minecraft:dennis", .nbt = null },
        .{ .name = "minecraft:graham", .nbt = null },
        .{ .name = "minecraft:creebet", .nbt = null },
        .{ .name = "minecraft:pond", .nbt = null },
        .{ .name = "minecraft:orb", .nbt = null },
        .{ .name = "minecraft:water", .nbt = null },
        .{ .name = "minecraft:sunset", .nbt = null },
        .{ .name = "minecraft:alban", .nbt = null },
        .{ .name = "minecraft:plant", .nbt = null },
        .{ .name = "minecraft:kebab", .nbt = null },
        .{ .name = "minecraft:backyard", .nbt = null },
        .{ .name = "minecraft:pool", .nbt = null },
        .{ .name = "minecraft:void", .nbt = null },
        .{ .name = "minecraft:skeleton", .nbt = null },
        .{ .name = "minecraft:tides", .nbt = null },
        .{ .name = "minecraft:wind", .nbt = null },
        .{ .name = "minecraft:donkey_kong", .nbt = null },
        .{ .name = "minecraft:passage", .nbt = null },
        .{ .name = "minecraft:finding", .nbt = null },
        .{ .name = "minecraft:owlemons", .nbt = null },
        .{ .name = "minecraft:lowmist", .nbt = null },
        .{ .name = "minecraft:endboss", .nbt = null },
        .{ .name = "minecraft:pointer", .nbt = null },
        .{ .name = "minecraft:baroque", .nbt = null },
        .{ .name = "minecraft:stage", .nbt = null },
        .{ .name = "minecraft:wanderer", .nbt = null },
        .{ .name = "minecraft:bomb", .nbt = null },
        .{ .name = "minecraft:aztec2", .nbt = null },
        .{ .name = "minecraft:aztec", .nbt = null },
    }
};