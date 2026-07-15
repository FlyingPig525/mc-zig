const std = @import("std");
const data = @import("data");
const protocol = @import("protocol");

pub const id = 0x44;
const PlayerInfoUpdate = @This();

// like the vanilla client, i will be sending a packet for each player, instead of combining them
// TODO: send a single packet for all players
uuid: u128,
actions: []const data.PlayerAction,

pub fn write(this: PlayerInfoUpdate, writer: *std.Io.Writer) !void {
    if (this.actions.len > @typeInfo(data.PlayerAction).@"union".fields.len) return error.ExcessActions;
    var byte: u8 = 0;
    for (this.actions) |action| {
        switch (action) {
            .add_player => {
                byte |= 0x01;
            },
            .initialize_chat => {
                byte |= 0x02;
            },
            .update_game_mode => {
                byte |= 0x04;
            },
            .update_listed => {
                byte |= 0x08;
            },
            .update_latency => {
                byte |= 0x10;
            },
            .update_display_name => {
                byte |= 0x20;
            },
            .update_list_priority => {
                byte |= 0x40;
            },
            .update_hat => {
                byte |= 0x80;
            },
        }
    }
    try writer.writeByte(byte);
    try protocol.VarInt.write(@intCast(this.actions.len), writer);
    for (this.actions) |action| {
        try action.write(writer);
    }
}