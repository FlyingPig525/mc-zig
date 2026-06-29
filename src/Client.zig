const std = @import("std");
const TcpClient = @import("TcpClient.zig");
const Server = @import("Server.zig");
const protocol = @import("protocol");
const packets = @import("packets");
const Packet = packets.Packet;

const Client = @This();
const log = std.log.scoped(.client);

tcp_client: TcpClient,
server: *Server,
state: std.atomic.Value(ConnectionState),
id: u16,
known_packs: std.array_hash_map.String([]const u8) = .empty,
kicked: bool = false,

pub fn init(tcp_client: TcpClient, server: *Server) Client {
    return .{
        .tcp_client = tcp_client,
        .state = .init(.handshake),
        .server = server,
        .id = @intCast(server.clients.items.len),
    };
}

pub fn deinit(this: *Client, alloc: std.mem.Allocator) void {
    this.tcp_client.deinit();
    this.known_packs.deinit(alloc);
}

pub const ConnectionState = enum(u8) {
    handshake,
    status,
    login,
    config,
    play,
};

pub fn kick(this: *Client, message: []const u8) void {
    this.kicked = true;
    var buf: [1024 * 16]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "{{text: \"{s}\"}}", .{ message }) catch {
        log.err("Buffer ran out of space in kick", .{});
        this.tcp_client.close();
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
    this.tcp_client.close();
}

pub fn sendPacket(this: *Client, packet: anytype) !void {
    try this.tcp_client.writeMessage(packet);
}

pub fn handleConnection(this: *Client, alloc: std.mem.Allocator) !void {
    while(this.state.load(.acquire) != .play) {
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
            .play => {
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
            for (packs.packs) |pack| {
                log.info("pack: {s}:{s} v{s}", .{ pack.namespace, pack.id, pack.version });
                try this.known_packs.put(alloc, try std.mem.concat(alloc, u8, &.{ pack.namespace, ":", pack.id }), pack.version);
            }
            if (!this.known_packs.contains("minecraft:core")) {
                this.kick("Missing pack minecraft:core");
            }
            const include_nbt = !std.mem.eql(u8, this.known_packs.get("minecraft:core").?, "1.21.10");
            // for (this.server.dynamic_registries.items) |registry| {
                // try this.sendPacket(clientbound.RegistryData{
                    // .registry = registry.*,
                    // .with_nbt = include_nbt,
                // });
            // }
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
            try this.sendPacket(clientbound.FinishConfiguration{});
        },
        serverbound.AcknowledgeFinish.id => {
            this.state.store(.play, .release);
            try this.sendPacket(packets.play.client.Login{
                .player_id = this.id,
                .dimension_names = &.{
                    "minecraft:overworld",
                },
                .dimension_name = "minecraft:overworld",
                .dimension_id = 0,
            });
            try this.sendPacket(packets.play.client.GameEvent{
                .data = .start_waiting_for_level_chunks,
            });
        },
        else => {
            log.warn("unknown packet id: {x}", .{ packet.id });
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
            try this.sendPacket(packets.login.client.LoginSuccess{
                .game_profile = .{
                    .uuid = start.uuid,
                    .username = start.name,
                    .properties = &.{}
                }
            });
        },
        serverbound.LoginAcknowledged.id => {
            log.info("login acknowledged", .{});
            this.state.store(.config, .release);
            this.sendPacket(packets.config.client.KnownPacks.mc_core) catch |err| {
                log.err("Error sending minecraft:core known pack packet: {any}", .{ err });
                this.kick("KnownPack packet error");
                return;
            };
        },
        else => {
            log.warn("unknown packet id: {x}", .{ packet.id });
            return;
        }
    }

}