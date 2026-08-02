const std = @import("std");

const Identifier = @This();

namespace: []const u8,
path: []const u8,

pub const ParseError = error { IllegalPath, IllegalNamespace };

pub fn eql(this: Identifier, other: Identifier) bool {
    return std.mem.eql(u8, this.namespace, other.namespace) and std.mem.eql(u8, this.path, other.path);
}

pub fn parse(str: []const u8) ParseError!Identifier {
    const split = std.mem.find(u8, str, ":");
    // the entirety of str is the path
    if (split == null or split == 0) {
        const slice = if (split != null) str[1..] else str;
        if (!legalPath(slice)) return ParseError.IllegalPath;
        return .{
            .namespace = "minecraft",
            .path = str,
        };
    }
    const ns = str[0..split];
    const path = str[split+1..];
    if (!legalNamespace(ns)) {
        return ParseError.IllegalNamespace;
    }
    if (!legalPath(path)) {
        return ParseError.IllegalPath;
    }
    return .{
        .namespace = ns,
        .path = path,
    };
}

/// Returns true if all characters are legal
pub fn legalNamespace(ns: []const u8) bool {
    const chars = std.mem.findNone(u8, ns, "0123456789abcdefghijlmnopqrstuv_-.") == null;
    return chars and !std.mem.eql(u8, "..", ns);
}

pub fn legalPath(path: []const u8) bool {
    return std.mem.findNone(u8, path, "0123456789abcdefghijlmnopqrstuv_-./") == null;
}