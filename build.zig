const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nbt = b.addModule("nbt", .{
        .root_source_file = b.path("src/nbt/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const protocol = b.addModule("protocol", .{
        .root_source_file = b.path("src/protocol/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const data = b.addModule("data", .{
        .root_source_file = b.path("src/data/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "protocol", .module = protocol },
        }
    });

    const registry = b.addModule("registry", .{
        .root_source_file = b.path("src/registry/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "protocol", .module = protocol },
            .{ .name = "data", .module = data },
            .{ .name = "nbt", .module = nbt },
        }
    });

    const packets = b.addModule("packets", .{
        .root_source_file = b.path("src/packets/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "protocol", .module = protocol },
            .{ .name = "data", .module = data },
            .{ .name = "nbt", .module = nbt },
            .{ .name = "registry", .module = registry },
        },
    });

    const mod = b.addModule("mc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "protocol", .module = protocol },
            .{ .name = "packets", .module = packets },
            .{ .name = "data", .module = data },
            .{ .name = "nbt", .module = nbt },
            .{ .name = "registry", .module = registry },
        }
    });

    const exe = b.addExecutable(.{
        .name = "mc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mc", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const nbt_tests = b.addTest(.{
        .root_module = nbt,
    });
    const run_nbt_tests = b.addRunArtifact(nbt_tests);

    const registry_tests = b.addTest(.{
        .root_module = registry,
    });
    const run_registry_tests = b.addRunArtifact(registry_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_nbt_tests.step);
    test_step.dependOn(&run_registry_tests.step);

    const gen_exe = b.addExecutable(.{
        .name = "gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("gen/main.zig"),
            .target = target,
            .optimize = optimize,
        })
    });
    b.installArtifact(gen_exe);

    const gen_step = b.step("gen", "Generate data from a game jar");
    const run_gen = b.addRunArtifact(gen_exe);
    run_gen.setCwd(b.path("gen"));
    gen_step.dependOn(&run_gen.step);
    gen_step.dependOn(b.getInstallStep());
}
