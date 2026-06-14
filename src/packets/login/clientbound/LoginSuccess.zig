const std = @import("std");
const protocol = @import("../../root.zig");
const data = @import("data");

const LoginSuccess = @This();
pub const id = 0x02;

game_profile: data.GameProfile,

pub fn write(this: LoginSuccess, writer: *std.Io.Writer) !void {
    try this.game_profile.write(writer);
}