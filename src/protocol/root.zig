pub const VarInt        = @import("VarInt.zig");
pub const String        = @import("String.zig");
pub const Uuid          = @import("Uuid.zig");
pub const Boolean       = @import("Boolean.zig");
/// Writes must be implemented manually
pub const PrefixedArray = @import("PrefixedArray.zig");

pub const max_packet_length = 2097151;
