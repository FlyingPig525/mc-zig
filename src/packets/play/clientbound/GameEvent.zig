const std = @import("std");
const protocol = @import("protocol");
const d = @import("data");
const GameMode = @import("Login.zig").GameMode;

pub const id = 0x26;
const GameEvent = @This();

data: EventData,

pub fn write(this: GameEvent, writer: *std.Io.Writer) !void {
    try writer.writeByte(@intFromEnum(this.data));
    switch (this.data) {
        .no_respawn_block,
        .begin_raining,
        .end_raining,
        .arrow_hit_player,
        .play_pufferfish_sting,
        .play_elder_appearance,
        .start_waiting_for_level_chunks => {
            try writer.writeAll(&.{ 0, 0, 0, 0 });
        },
        .change_game_mode => |data| {
            const float: f32 = @floatFromInt(@intFromEnum(data));
            try writer.writeInt(i32, @bitCast(float), .big);
        },
        .win_game => |data| {
            const float: f32 = @floatFromInt(@intFromEnum(data));
            try writer.writeInt(i32, @bitCast(float), .big);
        },
        .demo_event => |data| {
            const float: f32 = @floatFromInt(@intFromEnum(data));
            try writer.writeInt(i32, @bitCast(float), .big);
        },
        .rain_level_change, .thunder_level_change => |data| {
            try writer.writeInt(i32, @bitCast(data), .big);
        },
        .enable_respawn_screen, .limited_crafting => |data| {
            const float: f32 = if (!data) 1 else 0;
            try writer.writeInt(i32, @bitCast(float), .big);
        }
    }
}

pub const EventData = union(enum(u8)) {
    no_respawn_block: void = 0,
    begin_raining: void,
    end_raining: void,
    change_game_mode: GameMode,
    win_game: WinState,
    demo_event: DemoState,
    arrow_hit_player: void,
    /// ranges from 0 to 1
    rain_level_change: f32,
    /// ranges from 0 to 1
    thunder_level_change: f32,
    play_pufferfish_sting: void,
    play_elder_appearance: void,
    enable_respawn_screen: bool,
    limited_crafting: bool,
    start_waiting_for_level_chunks: void,

    pub const WinState = enum(u8) {
        just_respawn = 0,
        do_credits = 1,
    };

    pub const DemoState = enum(u8) {
        welcome_screen = 0,
        movement_controls = 101,
        jump_control = 102,
        inventory_control = 103,
        demo_over = 104,
    };
};