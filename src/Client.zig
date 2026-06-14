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

pub fn init(tcp_client: TcpClient, server: *Server) Client {
    return .{
        .tcp_client = tcp_client,
        .state = .init(.handshake),
        .server = server,
    };
}

pub fn deinit(this: *Client) void {
    this.tcp_client.deinit();
}

pub const ConnectionState = enum(u8) {
    handshake,
    status,
    login,
    config,
    play,
};

pub fn kick(this: *Client) void {
    switch (this.state.load(.acquire)) {
        .login => {
            this.sendPacket(packets.login.client.Kick{
                .message = "{text: \"fucku\"}"
            }) catch {
                log.err("Kick packet failed to send", .{});
            };
        },
        .config => {
            this.sendPacket(packets.config.client.Kick{
                .message = "{text: \"fucku\"}",
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

pub fn handleConnection(this: *Client) !void {
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
                this.handleConfigPacket(packet) catch |err| {
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

fn handleConfigPacket(this: *Client, packet: Packet) !void {
    const serverbound = packets.config.server;
    _ = this;
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
        },
        else => {
            log.warn("unknown packet id: {x}", .{ packet.id });
            return;
        }
    }

}