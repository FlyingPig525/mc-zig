const std = @import("std");
const net = std.Io.net;
const atomic = std.atomic;

const TcpServer = @import("TcpServer.zig");
const protocol = @import("root.zig").protocol;
const packets = @import("root.zig").packets;

const TcpClient = @This();

poll: std.posix.pollfd,
alloc: std.mem.Allocator,
stream: net.Stream,
reader: net.Stream.Reader,
writer: net.Stream.Writer,
read_buf: []u8,
write_buf: []u8,
io: std.Io,

pub fn init(stream: net.Stream, io: std.Io, alloc: std.mem.Allocator) !TcpClient {
    var client = TcpClient{
        .stream = stream,
        .alloc = alloc,
        .read_buf = undefined,
        .write_buf = undefined,
        .reader = undefined,
        .writer = undefined,
        .io = io,
        .poll = .{
            .fd = stream.socket.handle,
            .events = std.posix.POLL.IN,
            .revents = 0,
        },
    };
    client.read_buf = try alloc.alloc(u8, protocol.max_packet_length);
    client.write_buf = try alloc.alloc(u8, protocol.max_packet_length);
    client.reader = stream.reader(io, client.read_buf);
    client.writer = stream.writer(io, client.write_buf);
    return client;
}

pub fn close(this: *TcpClient) void {
    this.stream.close(this.io);
}

pub fn deinit(this: *TcpClient) void {
    this.alloc.free(this.read_buf);
    this.alloc.free(this.write_buf);
}

pub fn readMessage(this: *TcpClient) !?packets.Packet {
    _ = try std.posix.poll(@ptrCast(&this.poll), 0);

    if (this.poll.revents & std.posix.POLL.IN != std.posix.POLL.IN) {
        return null;
    }

    return try readMessageSync(this);
}

pub fn readMessageSync(this: *TcpClient) !packets.Packet {
    return try packets.Packet.read(&this.reader.interface);
}

pub fn writeMessage(this: *TcpClient, packet: anytype) !void {
    try packets.Packet.write(&this.writer.interface, packet);
    // std.log.debug("{x}", .{ this.writer.interface.buffered() });
    try this.writer.interface.flush();
}