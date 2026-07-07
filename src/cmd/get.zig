const std = @import("std");
const gpio = @import("gpio");

const print = gpio.print_utils.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    var args = try init.minimal.args.toSlice(alloc);

    if (args.len < 3) {
        print("Usage: {s} <gpiochip> <line...>\n\n", .{args[0]});
        return error.InsufficientArguments;
    }

    const path: []const u8 = if (hasPrefix(args[1], "gpiochip"))
        try std.mem.concat(alloc, u8, &.{ "/dev/", args[1] })
    else
        try std.mem.concat(alloc, u8, &.{ "/dev/gpiochip", args[1] });
    defer alloc.free(path);

    var chip = try gpio.getChip(path, io);
    defer chip.close();
    try chip.setConsumer("gpioget");

    var offsets = try std.ArrayList(u32).initCapacity(alloc, 10);
    defer offsets.deinit(alloc);

    // Iterate over each argument starting from the second one
    for (args[2..args.len]) |argument| {
        // Parse each argument as an integer and add it to offsets
        const offset = try std.fmt.parseUnsigned(u32, argument, 10);
        try offsets.append(alloc, offset);
    }

    var lines = try chip.requestLines(offsets.items, .{ .input = true });
    defer lines.close();
    const vals = try lines.getValues();

    var i: u32 = 0;
    while (i < args.len - 2) : (i += 1) {
        const value: u1 = if (vals.isSet(i)) 1 else 0;
        print("{d} ", .{value});
    }

    print("\n", .{});
}

fn hasPrefix(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    return (std.mem.eql(u8, s[0..prefix.len], prefix));
}
