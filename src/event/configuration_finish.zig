const root = @import("../root.zig");
const data = root.data;

pub fn ConfigurationFinish(comptime Manager: type) type {
    return struct {
        world: ?*root.World.ManagedWorld(Manager),
        spawn_position: data.Position,
    };
}
