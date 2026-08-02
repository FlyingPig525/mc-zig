pub fn Event(comptime Manager: type) type {
    return struct {
        pub const ConfigurationFinish = @import("configuration_finish.zig").ConfigurationFinish(Manager);
    };
}
