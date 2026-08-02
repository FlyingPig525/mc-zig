const std = @import("std");
const TcpClient = @import("TcpClient.zig");
const Server = @import("Server.zig");
const World = @import("World.zig");
const protocol = @import("root.zig").protocol;
const packets = @import("root.zig").packets;
const Packet = packets.Packet;
const data = @import("root.zig").data;

const log = std.log.scoped(.client);

pub fn ManagedClient(comptime Manager: type) type {
    return struct {
        const Client = @This();

        tcp_client: TcpClient,
        server: *Server.ManagedServer(Manager),
        state: std.atomic.Value(ConnectionState),
        id: u16,
        session_id: u128,
        arena: std.heap.ArenaAllocator,
        known_packs: std.array_hash_map.String([]const u8) = .empty,
        kicked: bool = false,
        recent_teleport_id: ?i32 = null,
        last_keep_alive: i64 = 0,
        info: UserInfo = .{
            .username = "",
            .uuid = 0,
        },

        pub const UserInfo = struct {
            username: []u8,
            uuid: u128,
        };

        pub fn init(tcp_client: TcpClient, session_id: u128, server: *Server.ManagedServer(Manager), alloc: std.mem.Allocator) !*Client {
            const ret = try alloc.create(Client);
            ret.* = .{
                .tcp_client = tcp_client,
                .state = .init(.handshake),
                .server = server,
                .id = @intCast(server.clients.items.len),
                .session_id = session_id,
                .arena = .init(alloc),
            };
            return ret;
        }

        pub fn deinit(this: *Client, alloc: std.mem.Allocator) void {
            this.tcp_client.deinit();
            this.known_packs.deinit(alloc);
            this.arena.deinit();
            alloc.destroy(this);
        }

        pub const ConnectionState = enum(u8) {
            handshake,
            status,
            login,
            config,
            play_setup,
            play,
        };

        pub fn kick(this: *Client, message: []const u8) void {
            this.kicked = true;
            defer this.tcp_client.close();
            var buf: [1024 * 16]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "{{text: \"{s}\"}}", .{ message }) catch {
                log.err("Buffer ran out of space in kick", .{});
                return;
            };
            switch (this.state.load(.acquire)) {
                .login => {
                    this.sendPacket(packets.login.client.Kick{
                        .message = msg
                    }) catch {
                        log.err("Kick packet failed to send", .{});
                    };
                },
                .config => {
                    this.sendPacket(packets.config.client.Kick{
                        .message = msg,
                    }) catch {
                        log.err("Kick packet failed to send", .{});
                    };
                },
                .play => {

                },
                else => {}
            }
        }

        pub fn sendPacket(this: *Client, packet: anytype) !void {
            try this.tcp_client.writeMessage(packet);
        }

        pub fn handleConnection(this: *Client, alloc: std.mem.Allocator) !void {
            while(this.state.load(.acquire) != .play_setup) {
                log.info("Reading message", .{});
                const packet = this.tcp_client.readMessageSync() catch |err| {
                    log.err("Failed to read client packet in login: {any}", .{ err });
                    return err;
                };
                switch (this.state.load(.acquire)) {
                    .handshake => {
                        log.debug("handshake", .{});
                        this.handleHandshakePacket(packet) catch |err| {
                            log.err("Failed to handle handshake state in login: {any}", .{ err });
                            return err;
                        };
                    },
                    .login => {
                        log.debug("login", .{});
                        this.handleLoginPacket(packet) catch |err| {
                            log.err("Failed to handle login state in login: {any}", .{ err });
                            return err;
                        };
                    },
                    .config => {
                        log.debug("config", .{});
                        this.handleConfigPacket(packet, alloc) catch |err| {
                            log.err("Failed to handle config state in login: {any}", .{ err });
                            return err;
                        };
                    },
                    .status => {
                        return;
                    },
                    else => {
                        return;
                    }
                }
            }
        }

        fn handleConfigPacket(this: *Client, packet: Packet, alloc: std.mem.Allocator) !void {
            const serverbound = packets.config.server;
            const clientbound = packets.config.client;
            switch (packet.id) {
                serverbound.ClientInformation.id => {
                    const info = try packet.into(serverbound.ClientInformation);
                    log.debug("client information packet. locale: {s} vd: {d} chat: {any} colors: {any} hand: {any} filtering: {any}", .{
                        info.locale,
                        info.view_distance,
                        info.chat_mode,
                        info.chat_colors,
                        info.main_hand,
                        info.text_filtering,
                    });
                },
                serverbound.KnownPacks.id => {
                    const packs = try packet.into(serverbound.KnownPacks);
                    var known_packs: std.array_hash_map.String([]const u8) = .empty;
                    defer {
                        var iter = known_packs.iterator();
                        while (iter.next()) |e| {
                            alloc.free(e.key_ptr.*);
                        }
                        known_packs.deinit(alloc);
                    }
                    for (packs.packs) |pack| {
                        log.info("pack: {s}:{s} v{s}", .{ pack.namespace, pack.id, pack.version });
                        try known_packs.put(alloc, try std.mem.concat(alloc, u8, &.{ pack.namespace, ":", pack.id }), pack.version);
                    }
                    // im not updating
                    if (!known_packs.contains("minecraft:core")) {
                        this.kick("Missing pack minecraft:core");
                        return error.Kicked;
                    }
                    const include_nbt = !std.mem.eql(u8, known_packs.get("minecraft:core").?, "1.21.10");
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .damage_type,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .biome,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .dimension,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .painting_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .cat_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .chicken_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .cow_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .frog_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .pig_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .wolf_sound_variant,
                        .with_nbt = include_nbt,
                    });
                    try this.sendPacket(clientbound.RegistryData{
                        .registry = .wolf_variant,
                        .with_nbt = include_nbt,
                    });
                    // try this.sendPacket(clientbound.RegistryData{
                        // .registry = .banner_pattern,
                        // .with_nbt = include_nbt,
                    // });
                    // try this.sendPacket(clientbound.RegistryData{
                        // .registry = .instrument,
                        // .with_nbt = include_nbt,
                    // });
                    // try this.sendPacket(clientbound.RegistryData{
                        // .registry = .zombie_nautilus_variant,
                        // .with_nbt = include_nbt,
                    // });
                    // try this.sendPacket(clientbound.RegistryData{
                        // .registry = .jukebox_song,
                        // .with_nbt = include_nbt,
                    // });
                    // try this.sendPacket(clientbound.RegistryData{
                        // .registry = .sulfur_cube_archetype,
                        // .with_nbt = include_nbt,
                    // });
                    try this.sendPacket(clientbound.FinishConfiguration{});
                },
                serverbound.AcknowledgeFinish.id => {
                    this.state.store(.play_setup, .release);
                },
                else => {
                    log.warn("unknown packet id in config: {x}", .{ packet.id });
                    return;
                }
            }
        }

        fn handleHandshakePacket(this: *Client, packet: Packet) !void {
            if (packet.id != 0x00) {
                log.err("Packet is not handshake. id: {d}", .{ packet.id });
                return error.NotHandshakePacket;
            }
            const handshake = try packet.into(packets.Handshake);
            log.info("{d} {s} {d} {any}", .{ handshake.protocol_version, handshake.server_address, handshake.server_port, handshake.intent });
            const state: ConnectionState = switch (handshake.intent) {
                .status => .status,
                .login, .transfer => .login,
            };
            this.state.store(state, .unordered);
        }

        fn handleLoginPacket(this: *Client, packet: Packet) !void {
            const serverbound = packets.login.server;
            switch (packet.id) {
                serverbound.LoginStart.id => {
                    const start = try packet.into(packets.login.server.LoginStart);
                    log.info("{s} {x}", .{ start.name, start.uuid });
                    this.info.uuid = start.uuid;
                    this.info.username = try this.arena.allocator().alloc(u8, start.name.len);
                    @memcpy(this.info.username, start.name);
                    try this.sendPacket(packets.login.client.LoginSuccess{
                        .game_profile = .{
                            .uuid = start.uuid,
                            .username = start.name,
                            .properties = &.{}
                        },
                        // .session_id = this.session_id,
                    });
                },
                serverbound.LoginAcknowledged.id => {
                    log.info("login acknowledged", .{});
                    this.state.store(.config, .release);
                    this.sendPacket(packets.config.client.KnownPacks.mc_core) catch |err| {
                        log.err("Error sending minecraft:core known pack packet: {any}", .{ err });
                        this.kick("KnownPack packet error");
                        return error.Kicked;
                    };
                },
                else => {
                    // log.warn("unknown packet id: {x}", .{ packet.id });
                    return;
                }
            }
        }

        pub fn tick(this: *Client) !void {
            const curr_tick = this.server.curr_tick.load(.acquire);

            if (this.last_keep_alive + 400 <= curr_tick) {
                this.kick("Timed out");
                log.err("Client timed out", .{});
                return error.Kicked;
            }

            while (try this.tcp_client.readMessage()) |raw| {
                switch (raw.id) {
                    packets.play.server.KeepAlive.id => {
                        this.last_keep_alive = curr_tick;
                    },
                    else => {
                        // log.warn("unknown packet id in tick: {x}", .{ raw.id });
                    }
                }
            }
        }

        pub fn setWorld(this: *Client, world: *World, alloc: std.mem.Allocator) !void {
            try world.addClient(this, alloc);
        }

        pub fn teleportVerbose(
            this: *Client,
            pos: data.Position,
            vel_x: f64, vel_y: f64, vel_z: f64,
            flags: data.TeleportFlags
        ) !void {
            const id = this.server.random.interface().int(i32);
            this.recent_teleport_id = id;
            try this.sendPacket(packets.play.client.SynchronizePlayerPosition{
                .x = pos.x, .y = pos.y, .z = pos.z,
                .vel_x = vel_x, .vel_y = vel_y, .vel_z = vel_z,
                .yaw = pos.yaw, .pitch = pos.pitch,
                .flags = flags,
                .teleport_id = id,
            });
        }

        pub fn teleportPos(this: *Client, x: f64, y: f64, z: f64) !void {
            try this.teleportVerbose(.{ .x = x, .y = y, .z = z }, 0, 0, 0, .abs_pos);
        }
    };
}
