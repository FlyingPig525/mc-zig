const std = @import("std");
const nfi = @import("NullFileIterator.zig");

pub fn create(minecraft: std.Io.Dir, io: std.Io, _: std.mem.Allocator) !void {
    try nfi.create(minecraft, io, "cat_variant");
    try nfi.create(minecraft, io, "chicken_variant");
    try nfi.create(minecraft, io, "cow_variant");
    try nfi.create(minecraft, io, "frog_variant");
    try nfi.create(minecraft, io, "pig_variant");
    try nfi.create(minecraft, io, "wolf_variant");
    try nfi.create(minecraft, io, "wolf_sound_variant");
    try nfi.create(minecraft, io, "damage_type");
    try nfi.create(minecraft, io, "painting_variant");
    // try nfi.create(minecraft, io, "sulfur_cube_archetype");
    // try nfi.create(minecraft, io, "instrument");
    // try nfi.create(minecraft, io, "banner_pattern");
    // try nfi.create(minecraft, io, "jukebox_song");
    // try nfi.create(minecraft, io, "trim_material");
    // try nfi.create(minecraft, io, "zombie_nautilus_variant");
}


pub const variant = true;