const std = @import("std");

const Item = struct {
    name: []const u8,
    src: []const u8,
};

/// List of examples
const examples = [_]Item{
    .{ .name = "blinky", .src = "examples/blinky.zig" },
    .{ .name = "multi", .src = "examples/multi.zig" },
};

/// List of commands
const commands = [_]Item{
    .{ .name = "gpiodetect", .src = "src/cmd/detect.zig" },
    .{ .name = "gpioinfo", .src = "src/cmd/info.zig" },
    .{ .name = "gpioget", .src = "src/cmd/get.zig" },
    .{ .name = "gpioset", .src = "src/cmd/set.zig" },
};

pub fn build(b: *std.Build) !void {
    const current_zig_version = @import("builtin").zig_version;
    if (current_zig_version.major != 0 or current_zig_version.minor < 16) {
        std.debug.print("This project does not compile with a Zig version <0.16.x. Exiting.", .{});
        std.process.exit(1);
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gpio_module = b.addModule("zig_gpio", .{
        .root_source_file = b.path("src/index.zig"),
        .target = target,
    });
    // Add the gpio module so it can be used by the package manager

    // Create a step to build all the examples
    const examples_step = b.step("examples", "build all the examples");

    // Add all the examples
    inline for (examples) |cfg| {
        std.debug.print("build the {s} example\n", .{cfg.name});
        const desc = try std.fmt.allocPrint(b.allocator, "build the {s} example", .{cfg.name});
        const step = b.step(cfg.name, desc);

        const exe = b.addExecutable(.{
            .name = cfg.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(cfg.src),
                .target = target,
                .optimize = optimize,
            }),
        });
        exe.root_module.addImport("gpio", gpio_module);

        const build_step = b.addInstallArtifact(exe, .{});
        step.dependOn(&build_step.step);
        examples_step.dependOn(&build_step.step);
        b.installArtifact(exe);
    }

    // Create a step to build all the commands
    const commands_step = b.step("commands", "build all the commands");

    // Add all the commands
    inline for (commands) |cfg| {
        std.debug.print("build the {s} command\n", .{cfg.name});
        const desc = try std.fmt.allocPrint(b.allocator, "build the {s} command", .{cfg.name});
        const step = b.step(cfg.name, desc);

        const exe = b.addExecutable(.{
            .name = cfg.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(cfg.src),
                .target = target,
                .optimize = optimize,}),
        });
        exe.root_module.addImport("gpio", gpio_module);

        const build_step = b.addInstallArtifact(exe, .{});
        step.dependOn(&build_step.step);
        commands_step.dependOn(&build_step.step);
        b.installArtifact(exe);
    }
}
