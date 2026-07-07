const std = @import("std");
const gpio = @import("gpio");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var iter_dir = try std.Io.Dir.openDirAbsolute(io, "/dev", .{ .iterate = true });
    defer iter_dir.close(io);

    var iter = iter_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (!hasPrefix(entry.name, "gpiochip")) continue;

        const fl = try iter_dir.openFile(io, entry.name, .{});
        var chip = try gpio.getChipByFd(fl.handle);
        defer chip.close(); // This will close the fd

        gpio.print_utils.print("{s} [{s}] ({d} lines)\n", .{ chip.nameSlice(), chip.labelSlice(), chip.lines });
    }
}

fn hasPrefix(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    return (std.mem.eql(u8, s[0..prefix.len], prefix));
}
