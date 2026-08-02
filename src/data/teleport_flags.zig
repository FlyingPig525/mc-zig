pub const TeleportFlags = packed struct {
    relative_x: bool = true,
    relative_y: bool = true,
    relative_z: bool = true,
    relative_yaw: bool = true,
    relative_pitch: bool = true,
    relative_vel_x: bool = true,
    relative_vel_y: bool = true,
    relative_vel_z: bool = true,
    /// Rotate velocity according to the change in rotation, before applying the velocity change in this packet.
    rotate_vel: bool = false,

    pub const abs_pos: TeleportFlags = .{
        .relative_x = false,
        .relative_y = false,
        .relative_z = false,
    };
    pub const abs_rot: TeleportFlags = .{
        .relative_yaw = false,
        .relative_pitch = false,
    };
    pub const abs_vel: TeleportFlags = .{
        .relative_vel_x = false,
        .relative_vel_y = false,
        .relative_vel_z = false,
    };

    pub const abs: TeleportFlags = abs_pos.plus(abs_rot).plus(abs_rot);

    pub fn plus(this: TeleportFlags, other: TeleportFlags) TeleportFlags {
        return .{
            .relative_x = this.relative_x or other.relative_x,
            .relative_y = this.relative_y or other.relative_y,
            .relative_z = this.relative_z or other.relative_z,
            .relative_yaw = this.relative_yaw or other.relative_yaw,
            .relative_pitch = this.relative_pitch or other.relative_pitch,
            .relative_vel_x = this.relative_vel_x or other.relative_vel_x,
            .relative_vel_y = this.relative_vel_y or other.relative_vel_y,
            .relative_vel_z = this.relative_vel_z or other.relative_vel_z,
            .rotate_vel = this.rotate_vel or other.rotate_vel,
        };
    }

    pub fn bits(this: TeleportFlags) u32 {
        return @intCast(@as(u9, @bitCast(this)));
    }
};