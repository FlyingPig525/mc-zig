pub const Handshake = @import("Handshake.zig");
pub const Packet    = @import("Packet.zig");

pub const login  = @import("login/root.zig");
pub const config = @import("config/root.zig");
pub const play   = @import("play/root.zig");

test {
    _ = Handshake;
    _ = Packet;
    _ = login;
    _ = config;
    _ = play;
}