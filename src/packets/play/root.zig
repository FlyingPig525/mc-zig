pub const client = @import("clientbound/root.zig");
pub const server = @import("serverbound/root.zig");

test {
    _ = client;
    _ = server;
}