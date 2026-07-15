const std = @import("std");
const protocol = @import("protocol");
const Flags = @import("data").TeleportFlags;

pub const id = 0x46;
const SynchronizePlayerPosition = @This();

teleport_id: i32,
x: f64,
y: f64,
z: f64,
vel_x: f64,
vel_y: f64,
vel_z: f64,
yaw: f32,
pitch: f32,
flags: Flags,

pub fn write(this: SynchronizePlayerPosition, writer: *std.Io.Writer) !void {
    try protocol.VarInt.write(this.teleport_id, writer);
    try writer.writeInt(u64, @bitCast(this.x), .big);
    try writer.writeInt(u64, @bitCast(this.y), .big);
    try writer.writeInt(u64, @bitCast(this.z), .big);
    try writer.writeInt(u64, @bitCast(this.vel_x), .big);
    try writer.writeInt(u64, @bitCast(this.vel_y), .big);
    try writer.writeInt(u64, @bitCast(this.vel_z), .big);
    try writer.writeInt(u32, @bitCast(this.yaw), .big);
    try writer.writeInt(u32, @bitCast(this.pitch), .big);
    try writer.writeInt(u32, @call(.always_inline, Flags.bits, .{ this.flags }), .big);
}