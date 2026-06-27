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

}
