const std = @import("std");
const protocol = @import("protocol");

const GameProfile = @import("GameProfile.zig");

pub const PlayerAction = union(enum) {
    add_player: AddPlayer,
    // TODO
    initialize_chat: void,
    update_game_mode: void,
    update_listed: void,
    update_latency: void,
    update_display_name: void,
    update_list_priority: void,
    update_hat: void,

    pub const AddPlayer = struct {
        name: []const u8,
        properties: []const GameProfile.Property,

        pub fn write(this: AddPlayer, writer: *std.Io.Writer) !void {
            try protocol.String.write(this.name, writer);
            for (this.properties) |prop| {
                try prop.write(writer);
            }
        }
    };

    pub fn write(this: PlayerAction, writer: *std.Io.Writer) !void {
        switch (this) {
            .add_player => |action| {
                try action.write(writer);
            },
            else => unreachable,
        }
    }
};