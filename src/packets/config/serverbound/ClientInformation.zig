const std = @import("std");
const protocol = @import("protocol");

const ClientInformation = @This();
pub const id = 0x00;

locale: []const u8,
view_distance: u8,
chat_mode: ChatMode,
chat_colors: bool,
displayed_skin_parts: SkinParts,
main_hand: MainHand,
text_filtering: bool,
allow_server_listing: bool,
particle_status: ParticleStatus,

pub fn read(reader: *std.Io.Reader) !ClientInformation {
    return .{
        .locale = try protocol.String.read(reader),
        .view_distance = try reader.takeInt(u8, .big),
        .chat_mode = @enumFromInt(try protocol.VarInt.read(reader)),
        .chat_colors = try protocol.Boolean.read(reader),
        .displayed_skin_parts = @bitCast(try reader.takeByte()),
        .main_hand = @enumFromInt(try protocol.VarInt.read(reader)),
        .text_filtering = try protocol.Boolean.read(reader),
        .allow_server_listing = try protocol.Boolean.read(reader),
        .particle_status = @enumFromInt(try protocol.VarInt.read(reader)),
    };
}

pub const ChatMode = enum(u8) {
    enabled = 0,
    commands_only = 1,
    hidden = 2,
};

pub const SkinParts = packed struct {
    cape: bool,
    jacket: bool,
    left_sleeve: bool,
    right_sleeve: bool,
    left_pant: bool,
    right_pant: bool,
    hat: bool,
    _: u1,
};

pub const MainHand = enum(u8) {
    left = 0,
    right = 1,
};

pub const ParticleStatus = enum(u8) {
    all = 0,
    decreased = 1,
    minimal = 2,
};