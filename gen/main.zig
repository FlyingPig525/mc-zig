const std = @import("std");

const required_registries = [_]type{
    // @import("DamageType.zig"),
    // defined by user
    // "dimension_type",
    // "painting_variant",
    // only plains
    // "worldgen/biome",
    @import("Variants.zig"),
    // "chicken_variant",
    // "cow_variant",
    // "frog_variant",
    // "pig_variant",
    // "wolf_variant",
    // "wolf_sound_variant",
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    var arg_iter = try init.minimal.args.iterateAllocator(gpa);
    defer arg_iter.deinit();
    var generate_variants = false;
    while (arg_iter.next()) |arg| {
        if (std.mem.eql(u8, "variant", arg[0..])) {
            generate_variants = true;
        }
    }

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
    const minecraft = try (try dir.openDir(io, "data", .{})).openDir(io, "minecraft", .{});

    inline for (required_registries) |reg| {
        if (@hasDecl(reg, "variant")) {
            if (generate_variants) reg.create(minecraft, io, gpa) catch |e| regErr(reg, e);
            continue;
        }
        reg.create(minecraft, io, gpa) catch |e| regErr(reg, e);
    }
}
fn regErr(comptime reg: type, e: anyerror) void {
    std.log.err("Error processing registry: {s} ; err: {any}", .{ @typeName(reg), e });
}

fn extract(gpa: std.mem.Allocator, jar: std.Io.File, io: std.Io) !std.Io.Dir {
    const buf = try gpa.alloc(u8, @intCast(try jar.length(io)));
    defer gpa.free(buf);
    std.log.info("Trying to create extracted dir", .{});

    std.Io.Dir.cwd().deleteTree(io, "extracted") catch {};
    try std.Io.Dir.cwd().createDirPath(io, "extracted");

    std.log.info("Running datagen in jar", .{});

    var filename_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const path_end = try jar.realPath(io, &filename_buf);

    var child = try std.process.spawn(io, .{
        .argv = &.{ "java", "-DbundlerMainClass=net.minecraft.data.Main", "-jar", filename_buf[0..path_end], "--reports", "--server", "--output", "extracted/" },
        .create_no_window = true,
    });
    const term = try child.wait(io);
    if (term.exited != 0) {
        std.log.err("Error in child datagen process. Exit code: {x:0>2}", .{ term.exited });
    } else {
        std.log.info("Child datagen process exited successfully", .{});
    }

    std.log.info("Cleaning up", .{});
    std.Io.Dir.cwd().deleteTree(io, "libraries") catch {};
    std.Io.Dir.cwd().deleteTree(io, "versions") catch {};
    std.Io.Dir.cwd().deleteTree(io, "logs") catch {};
    std.log.info("Cleaned up", .{});

    std.log.info("Extracted successfully", .{});
    return std.Io.Dir.cwd().openDir(io, "extracted", .{});
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
    // std.log.info("old: {any}, new: {any}", .{ &old_buf, &out_buf });
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