const std = @import("std");
const gpio = @import("gpio");

const print = gpio.print_utils.print;

pub fn main(init: std.process.Init) !void {

    var gpa = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    const io = init.io;
    var dir = try std.Io.Dir.openDirAbsolute(io, "/dev", .{});
    defer dir.close(io);

    var args = init.minimal.args.iterate();
    _ = args.skip(); // Skip the program name

    // Iterate over each argument
    while (args.next()) |argument| {
        const hasGpiochip = hasPrefix(argument, "gpiochip");

        // If the argument has the "gpiochip" prefix,
        // just use it unchanged. Otherwise, add the prefix.
        const filename: []const u8 = if (hasGpiochip)
            argument
        else
            try std.mem.concat(alloc, u8, &.{ "gpiochip", argument });

        // We only need to free if we actually allocated,
        // which only happens if there was no prefix.
        defer if (!hasGpiochip) alloc.free(filename);

        const fl = try dir.openFile(io, filename, .{});
        var chip = try gpio.getChipByFd(fl.handle);
        defer chip.close(); // This will close the fd

        print("{s} - {d} lines:\n", .{ chip.nameSlice(), chip.lines });

        var offset: u32 = 0;
        while (offset < chip.lines) : (offset += 1) {
            const lineInfo = try chip.getLineInfo(offset);

            // Create an arraylist to store all the flag strings
            var flags = try std.ArrayList([]const u8).initCapacity(alloc, 10);
            defer flags.deinit(alloc);

            const line_flags: gpio.uapi.LineFlags = @bitCast(lineInfo.flags);

            // Appand any relevant flag strings to the array list
            if (line_flags.input) try flags.append(alloc, "input");
            if (line_flags.output) try flags.append(alloc,"output");
            if (line_flags.used) try flags.append(alloc,"used");
            if (line_flags.active_low) try flags.append(alloc,"active_low");
            if (line_flags.edge_rising) try flags.append(alloc,"edge_rising");
            if (line_flags.edge_falling) try flags.append(alloc,"edge_falling");
            if (line_flags.open_drain) try flags.append(alloc,"open_drain");
            if (line_flags.open_source) try flags.append(alloc,"open_source");
            if (line_flags.bias_pull_up) try flags.append(alloc,"bias_pull_up");
            if (line_flags.bias_pull_down) try flags.append(alloc,"bias_pull_down");

            // Join the array list into a string
            const flagStr = try std.mem.join(alloc, ", ", flags.items);
            defer alloc.free(flagStr);

            const name = if (lineInfo.name[0] != 0) lineInfo.nameSlice() else "<unnamed>";
            const consumer = if (line_flags.used) lineInfo.consumerSlice() else "<unused>";

            print("    line {d}: {s} {s} [{s}]\n", .{ offset, name, consumer, flagStr });
        }
    }
}

fn hasPrefix(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    return (std.mem.eql(u8, s[0..prefix.len], prefix));
}
