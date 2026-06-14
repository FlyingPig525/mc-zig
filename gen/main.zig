const std = @import("std");

const required_registries: []const []const u8 = .{
    "damage_type",
    // defined by user
    "dimension_type",
    "painting_variant",
    // only plains
    "worldgen/biome",
    "cat_variant",
    "chicken_variant",
    "cow_variant",
    "frog_variant",
    "pig_variant",
    "wolf_variant",
    "wolf_sound_variant",
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    std.log.info("Opening jar", .{});
    const jar = std.Io.Dir.cwd().openFile(init.io, "game.jar", .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.err("Game jar not found! To use this module, place the minecraft client jar in this gen/ directory, then name it \"game.jar\"", .{});
            return error.GameJarNotFound;
        },
        else => return err,
    };
    defer jar.close(io);

    std.log.info("Checking hash", .{});
    var dir: std.Io.Dir = undefined;
    defer dir.close(io);
    if (try needsExtraction(jar, io)) {
        std.log.info("Hash is different", .{});
        dir = try extract(gpa, jar, io);
    } else {
        std.log.info("Hash is the same", .{});
        dir = try std.Io.Dir.cwd().openDir(io, "extracted", .{});
    }
}

fn extract(gpa: std.mem.Allocator, jar: std.Io.File, io: std.Io) !std.Io.Dir {
    const buf = try gpa.alloc(u8, @intCast(try jar.length(io)));
    defer gpa.free(buf);
    var reader = jar.reader(io, buf);
    std.log.info("Trying to create extracted dir", .{});

    std.Io.Dir.cwd().deleteTree(io, "extracted") catch {};
    try std.Io.Dir.cwd().createDirPath(io, "extracted");

    std.log.info("Extracting jar into dir", .{});
    var iter = try std.zip.Iterator.init(&reader);
    var progress = std.Progress.start(io, .{
        .root_name = "",
        .estimated_total_items = iter.cd_record_count,
    });

    const dest = try std.Io.Dir.cwd().openDir(io, "extracted", .{});
    var diagnostics = std.zip.Diagnostics{
        .allocator = gpa
    };

    var filename_buf: [std.fs.max_path_bytes]u8 = undefined;
    while (try iter.next()) |entry| {
        try diagnostics.nextFilename(filename_buf[0..entry.filename_len]);

        try entry.extract(&reader, .{}, &filename_buf, dest);
        progress.setName(filename_buf[0..entry.filename_len]);
        progress.completeOne();
    }
    progress.end();
    std.log.info("Extracted successfully", .{});
    return dest;
}

const hash_file_name = "hash.md5";

/// Returns true if the file is different from the last run
fn needsExtraction(file: std.Io.File, io: std.Io) !bool {
    const Md5 = std.crypto.hash.Md5;
    var old_buf: [Md5.digest_length]u8 = undefined;
    @memset(old_buf[0..], 0);
    _ = std.Io.Dir.cwd().readFile(io, hash_file_name, &old_buf) catch |err| {
        if (err == error.FileNotFound) {
            (try std.Io.Dir.cwd().createFile(io, hash_file_name, .{})).close(io);
        } else return err;
    };
    var new_hash = Md5.init(.{});
    var buf: [1024 * 1024]u8 = undefined;
    var reader = file.reader(io, &buf);

    while (!std.meta.isError(reader.interface.fillMore())) {
        new_hash.update(reader.interface.buffered());
        reader.interface.tossBuffered();
    }

    var out_buf: [Md5.digest_length]u8 = undefined;
    new_hash.final(&out_buf);
    std.log.info("old: {any}, new: {any}", .{ &old_buf, &out_buf });
    const res = std.mem.eql(u8, &old_buf, &out_buf);
    if (!res) {
        try std.Io.Dir.cwd().deleteFile(io, hash_file_name);
        const hash_file = try std.Io.Dir.cwd().createFile(io, hash_file_name, .{});
        hash_file.close(io);
        try std.Io.Dir.cwd().writeFile(io, .{
            .sub_path = hash_file_name,
            .data = &out_buf,
        });
    }
    return !res;
}