const std = @import("std");

const AcknowledgeFinish = @This();
pub const id = 0x03;

pub fn read(_: *std.Io.Reader) !AcknowledgeFinish {
    return .{};
}