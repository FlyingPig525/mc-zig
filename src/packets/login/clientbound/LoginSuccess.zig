const std = @import("std");
const data = @import("../../../root.zig").data;
const protocol = @import("../../../root.zig").protocol;

const LoginSuccess = @This();
pub const id = 0x02;

game_profile: data.GameProfile,
// session_id: u128,

pub fn write(this: LoginSuccess, writer: *std.Io.Writer) !void {
    try this.game_profile.write(writer);
    // try protocol.Uuid.write(this.session_id, writer);
}