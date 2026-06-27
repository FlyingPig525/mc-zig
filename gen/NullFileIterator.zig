const std = @import("std");

pub fn create(minecraft: std.Io.Dir, io: std.Io, dir_name: []const u8) !void {
    const dir = try minecraft.openDir(io, dir_name, .{
        .iterate = true,
    });
    defer dir.close(io);
    // const out_file = try std.Io.Dir.cwd().createFile(io, "CatVariants.zig", .{});
    // defer out_file.close(io);
    // var out_buf: [1024]u8 = undefined;
    // var writer = out_file.writer(io, &out_buf);
    // defer writer.flush() catch {};
    // 
    // writer.interface.writeAll(
    //     \\ 
    //     \\
    // );
    std.debug.print(
        \\pub const {s}: Registry = .{{
        \\    .name = "minecraft:{s}",
        \\    .entries = &.{{
        \\
    , .{ dir_name, dir_name });
    var iter = dir.iterateAssumeFirstIteration();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;
        std.debug.print("        .{{ .name = \"minecraft:{s}\", .nbt = null }},\n", .{ std.mem.cutSuffix(u8, entry.name, ".json") orelse entry.name });
        // const file = try dir.openFile(io, entry.name, .{});
        // const read_buf = try alloc.alloc(u8, try file.length(io));
        // const reader = file.reader(io, read_buf);
        // reader.interface.fillMore() catch |err| { std.log.err("Recieved err in file {s} {any}", .{ entry.name, err }); };
        // const content = reader.interface.buffered();
        // const scanner = std.json.Scanner.initCompleteInput(alloc, content);
        // const value = try std.json.Value.jsonParse(alloc, scanner, .{});
        // const obj = value.object;
        
    }
    std.debug.print(
        \\    }}
        \\}};
        \\
    , .{});
}