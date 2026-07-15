const Position = @This();

x: f64,
y: f64,
z: f64,
yaw: f32 = 0,
pitch: f32 = 0,

pub fn add(this: Position, other: Position) Position {
    return .{
        .x = this.x + other.x,
        .y = this.y + other.y,
        .z = this.z + other.z,
        .yaw = this.yaw + other.yaw,
        .pitch = this.pitch + other.pitch,
    };
}

pub fn sub(this: Position, other: Position) Position {
    return .{
        .x = this.x - other.x,
        .y = this.y - other.y,
        .z = this.z - other.z,
        .yaw = this.yaw - other.yaw,
        .pitch = this.pitch - other.pitch,
    };
}