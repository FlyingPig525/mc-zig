const std = @import("std");
const data = @import("root.zig");

const Material = @This();

identifier: data.Identifier,

pub fn eql(this: Material, other: Material) bool {
    return this.identifier.eql(other.identifier);
}