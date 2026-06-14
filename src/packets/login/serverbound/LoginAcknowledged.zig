const std = @import("std");

const LoginAcknowledged = @This();

pub const id = 0x03;

pub fn read(_: *std.Io.Reader) LoginAcknowledged {
    return .{};
}