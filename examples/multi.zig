const std = @import("std");
const gpio = @import("gpio");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var chip = try gpio.getChip("/dev/gpiochip0", io);
    defer chip.close();
    try chip.setConsumer("multi");

    std.debug.print("Chip Name: {s}\n", .{chip.name});

    // Request the lines with offsets 26, 27, 28, and 29 as outputs.
    var lines = try chip.requestLines(&.{ 26, 27, 28, 29 }, .{ .output = true });
    defer lines.close();
    // Alternate between lines 27/29 and 26/28 being high
    while (true) {
        // Set lines 27 and 29 as low (off)
        try lines.setLow(&.{ 1, 3 });
        // Set lines 26 and 28 as high (on)
        try lines.setHigh(&.{ 0, 2 });
        io.sleep(.fromSeconds(1), .awake) catch {};
        // Set lines 26 and 28 as low (off)
        try lines.setLow(&.{ 0, 2 });
        // Set lines 27 and 28 as high (on)
        try lines.setHigh(&.{ 1, 3 });
        io.sleep(.fromSeconds(1), .awake) catch {};
    }
}
