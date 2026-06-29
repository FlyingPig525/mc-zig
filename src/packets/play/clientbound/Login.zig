const std = @import("std");
const protocol = @import("protocol");
const data = @import("data");

const Login = @This();

pub const id = 0x30;

player_id: i32,
hardcore: bool = false,
dimension_names: []const []const u8,
view_distance: u8 = 12,
simulation_distance: u8 = 12,
reduced_debug_info: bool = false,
respawn_screen: bool = true,
limited_crafting: bool = false,
dimension_id: u8,
dimension_name: []const u8,
hashed_seed: u64 = 0,
game_mode: GameMode = .survival,
previous_game_mode: PreviousGameMode = .undef,
is_debug: bool = false,
is_flat: bool = false,
death_location: ?DeathLocation = null,
portal_cooldown: i32 = 0,
sea_level: i32 = 0,
secure_chat: bool = false,

pub const DeathLocation = struct {
    dimension_name: []u8,
    location: data.Position,
};

pub fn write(this: Login, writer: *std.Io.Writer) !void {
    try writer.writeInt(i32, this.player_id, .big);
    try protocol.Boolean.write(this.hardcore, writer);
    try protocol.VarInt.write(@intCast(this.dimension_names.len), writer);
    for (this.dimension_names) |name| {
        try protocol.String.write(name, writer);
    }
    try protocol.VarInt.write(128, writer);
    try protocol.VarInt.write(this.view_distance, writer);
    try protocol.VarInt.write(this.simulation_distance, writer);
    try protocol.Boolean.write(this.reduced_debug_info, writer);
    try protocol.Boolean.write(this.respawn_screen, writer);
    try protocol.Boolean.write(this.limited_crafting, writer);
    try protocol.VarInt.write(this.dimension_id, writer);
    try protocol.String.write(this.dimension_name, writer);
    try writer.writeInt(u64, this.hashed_seed, .big);
    try writer.writeByte(@intFromEnum(this.game_mode));
    try writer.writeByte(@bitCast(@intFromEnum(this.previous_game_mode)));
    try protocol.Boolean.write(this.is_debug, writer);
    try protocol.Boolean.write(this.is_flat, writer);
    try protocol.Boolean.write(this.death_location != null, writer);
    if (this.death_location) |loc| {
        try protocol.String.write(loc.dimension_name, writer);
        try loc.location.write(writer);
    }
    try protocol.VarInt.write(this.portal_cooldown, writer);
    try protocol.VarInt.write(this.sea_level, writer);
    try protocol.Boolean.write(this.secure_chat, writer);
}

pub const GameMode = enum(u8) {
    survival = 0,
    creative = 1,
    adventure = 2,
    spectator = 3,
};
pub const PreviousGameMode = enum(i8) {
    undef = -1,
    survival = 0,
    creative = 1,
    adventure = 2,
    spectator = 3,
};