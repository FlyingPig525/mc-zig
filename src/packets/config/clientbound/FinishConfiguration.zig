const std = @import("std");

const FinishConfiguration = @This();
pub const id = 0x03;

pub fn write(_: FinishConfiguration, _: *std.Io.Writer) !void {}