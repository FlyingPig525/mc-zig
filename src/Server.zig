const std = @import("std");
const atomic = std.atomic;

const World = @import("World.zig");
const TcpServer = @import("TcpServer.zig");
const TcpClient = @import("TcpClient.zig");
const Client = @import("Client.zig");

const Server = @This();
const log = std.log.scoped(.server);

io: std.Io,
alloc: std.mem.Allocator,
worlds: []World,
tcp_server: TcpServer,
clients: std.ArrayList(Client),
main_thread: std.Thread.Id,
curr_tick: atomic.Value(u64) = .init(0),
running: atomic.Value(bool) = .init(true),
after_tick: ?*const fn (server: *Server, tick_ns: i96) void = null,

pub fn init(alloc: std.mem.Allocator, io: std.Io) !Server {
    return .{
        .io = io,
        .alloc = alloc,
        .tcp_server = try .init(alloc, io),
        .worlds = &.{},
        .clients = .empty,
        .main_thread = std.Thread.getCurrentId(),
    };
}

pub fn deinit(this: *Server) void {
    for (0..this.clients.items.len) |i| {
        this.clients.items[i].deinit();
    }
    this.tcp_server.deinit();
}

pub fn start(this: *Server, address: std.Io.net.IpAddress) !void {
    if (this.main_thread != std.Thread.getCurrentId()) return error.NotMainThread;
    log.info("Starting tcp server", .{});
    try this.tcp_server.start(address);
    log.info("Tcp server started", .{});

    while (true) {
        const clock = std.Io.Clock.now(.boot, this.io);
        while (try this.tcp_server.pollAccept()) |tcp_client| {
            log.info("Client accepted", .{});
            try this.clients.append(this.alloc, .{
                .state = .init(.handshake),
                .tcp_client = tcp_client,
                .server = this,
            });
            const client = &this.clients.items[this.clients.items.len - 1];
            _ = try this.io.concurrent(handle_login, .{ this, client, this.clients.items.len - 1 });
        }

        try this.tick();
        const dur = clock.untilNow(this.io, .boot);
        if (this.after_tick) |after_tick| after_tick(this, dur.nanoseconds);
        try this.io.sleep(.fromMilliseconds(1000 / 20), .awake);
    }
}

fn handle_login(this: *Server, client: *Client, index: usize) void {
    client.handleConnection() catch |err| {
        log.err("Error in client login sequence: {any}", .{ err });
        client.kick();
        // client.deinit();
        _ = this.clients.swapRemove(index);
    };
}

fn tick(this: *Server) !void {
    this.curr_tick.store(this.curr_tick.load(.acquire), .release);
}