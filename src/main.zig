const std = @import("std");
const Io = std.Io;

const mc = @import("mc");

pub fn main(init: std.process.Init) !void {
    var server = try mc.Server.init(init.gpa, init.io);
    defer server.deinit();
    try server.start(try .parse("0.0.0.0", 25565));
}