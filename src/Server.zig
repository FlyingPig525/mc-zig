const std = @import("std");
const atomic = std.atomic;

const World = @import("World.zig");
const TcpServer = @import("TcpServer.zig");
const TcpClient = @import("TcpClient.zig");
const ManagedClient = @import("Client.zig").ManagedClient;
const reg = @import("registry");
const packets = @import("packets");

const log = std.log.scoped(.server);
pub fn ManagedServer(comptime Manager: type) type {
    return struct {
        const Server = @This();
        const Client = ManagedClient(Manager);

        io: std.Io,
        alloc: std.mem.Allocator,
        tcp_server: TcpServer,
        clients: std.ArrayList(*Client),
        main_thread: std.Thread.Id,
        manager: *Manager,
        random: std.Random.IoSource,
        curr_tick: atomic.Value(i64) = .init(0),
        last_keep_alive: i64 = 0,
        running: atomic.Value(bool) = .init(true),

        pub fn init(alloc: std.mem.Allocator, io: std.Io, manager: *Manager) !Server {
            const s: Server = .{
                .io = io,
                .alloc = alloc,
                .tcp_server = try .init(alloc, io),
                .clients = .empty,
                .main_thread = std.Thread.getCurrentId(),
                .manager = manager,
                .random = std.Random.IoSource{
                    .io = io,
                },
            };
            return s;
        }

        pub fn deinit(this: *Server) void {
            for (0..this.clients.items.len) |i| {
                this.clients.items[i].deinit(this.alloc);
            }
            this.clients.deinit(this.alloc);
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
                    const session_id = this.random.interface().int(u128);
                    log.info("Client accepted, session_id: {x}", .{ session_id });
                    try this.clients.append(this.alloc, try .init(tcp_client, session_id, this, this.alloc));
                    const client = this.clients.items[this.clients.items.len - 1];
                    _ = try this.io.concurrent(handle_login, .{ this, client, this.clients.items.len - 1 });
                }

                try this.tick();
                const dur = clock.untilNow(this.io, .boot);
                if (std.meta.hasFn(Manager, "tickEnd")) {
                    this.manager.tickEnd(this, dur.nanoseconds) catch |err| {
                        log.err("Error in manager tickEnd: {any}", .{ err });
                        printStacktrace(this.alloc);
                    };
                }
                try this.io.sleep(.fromMilliseconds(1000 / 20), .awake);
            }
        }

        fn handle_login(this: *Server, client: *Client, index: usize) void {
            client.handleConnection(this.alloc) catch |err| {
                log.err("Error in client login sequence: {any}", .{ err });
                if (!client.kicked) {
                    client.kick("Internal server error");
                }
                client.deinit(this.alloc);
                // client.deinit();
                _ = this.clients.swapRemove(index);
                return;
            };
            if (std.meta.hasFn(Manager, "onConfigureFinish")) {
                this.manager.onConfigureFinish(this, client) catch |err| {
                    log.err("Error in manager onConfigureFinish: {any}", .{ err });
                    printStacktrace(this.alloc);
                };
            }
        }

        pub const DisconnectOptions = struct {
            index: ?usize = null,
            message: ?[]const u8 = null,
        };

        pub fn disconnect(this: *Server, client: *Client, opt: DisconnectOptions) void {
            if (!client.kicked) {
                client.kick(if (opt.message) |m| m else "Disconnect");
            }
            log.info("Client {s} closed", .{ client.info.username });
            var i: ?usize = opt.index;
            if (i == null) {
                for (this.clients.items, 0..) |c, idx| {
                    if (@intFromPtr(c) == @intFromPtr(client)) i = idx;
                }
            }
            if (i == null) {
                log.warn("Couldnt find client index to disconnect. addr: {x}, name: {s}", .{
                    @intFromPtr(client),
                    client.info.username
                });
                return;
            }
            _ = this.clients.swapRemove(i.?);
        }

        fn tick(this: *Server) !void {
            const curr_tick = this.curr_tick.load(.acquire) + 1;
            this.curr_tick.store(curr_tick, .release);

            for (this.clients.items, 0..) |client, i| {
                if (client.kicked) continue;
                if (client.state.load(.acquire) != .play) continue;
                if (curr_tick - 280 >= this.last_keep_alive) {
                    client.sendPacket(packets.play.client.KeepAlive{
                        .out_id = curr_tick,
                    }) catch |err| {
                        log.err("Failed to send keepalive packet. err: {any}", .{ err });
                        printStacktrace(this.alloc);
                        this.disconnect(client, .{ .index = i, .message = "Internal server error" });
                        continue;
                    };
                }

                client.tick() catch |err| {
                    if (err == error.Kicked) {
                        log.info("Client {s} kicked during client tick", .{ client.info.username });
                        continue;
                    }
                    if (err != error.EndOfStream) {
                        log.err("Error in client tick: {any}", .{ err });
                        printStacktrace(this.alloc);
                    }
                    this.disconnect(client, .{ .index = i, .message = "Internal server error" });
                    continue;
                };
            }
        }
    };
}

fn printStacktrace(allocator: std.mem.Allocator) void {
    if (@errorReturnTrace()) |trace| {
        var err_trace: std.Io.Writer.Allocating = .init(allocator);
        defer err_trace.deinit();
        std.debug.writeErrorReturnTrace(trace, .{ .writer = &err_trace.writer, .mode = .no_color }) catch |err2| {
            log.err("error writing error return trace: {}", .{err2});
        };
        log.err("trace: {s}", .{ err_trace.written() });
    }
}