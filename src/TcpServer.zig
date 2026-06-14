const std = @import("std");
const net = std.Io.net;

const TcpClient = @import("TcpClient.zig");

const TcpServer = @This();

io: std.Io,
alloc: std.mem.Allocator,
server: net.Server,
poll: std.posix.pollfd,

pub fn init(alloc: std.mem.Allocator, io: std.Io) !TcpServer {
    const s: TcpServer = .{
        .io = io,
        .alloc = alloc,
        .server = undefined,
        .poll = undefined,
    };
    return s;
}

pub fn deinit(this: *TcpServer) void { _ = this; }

pub fn close(this: *TcpServer) void {
    this.server.close(this.io);
}

pub fn start(this: *TcpServer, address: net.IpAddress) !void {
    this.server = try address.listen(this.io, .{
        .mode = .stream,
        .protocol = .tcp,
        .reuse_address = true,
    });
    this.poll = .{
        .fd = this.server.socket.handle,
        .events = std.posix.POLL.IN,
        .revents = 0,
    };
}

/// Attempts to establish a connection with an awaiting tcp client. Returns null if there is no queued tcp client.
///
/// tcp clients' allocations are freed once the TcpServer is deinitialized. All clients should always be deinitialized before calling
/// this method
pub fn pollAccept(this: *TcpServer) !?TcpClient {
    std.log.debug("{d} {d}", .{ this.poll.revents, this.poll.events });
    _ = try std.posix.poll(@alignCast(@ptrCast(&this.poll)), -1);
    if (this.poll.revents & std.posix.POLL.IN != std.posix.POLL.IN) {
        return null;
    }

    const stream = try this.server.accept(this.io);
    const client = try TcpClient.init(stream, this.io, this.alloc);
    return client;
}