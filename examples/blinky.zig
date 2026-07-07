const std = @import("std");
const gpio = @import("gpio");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var chip = try gpio.getChip("/dev/gpiochip22", io);
    defer chip.close();
    try chip.setConsumer("blinky");

    std.debug.print("Chip Name: {s}\n", .{chip.name});

    var line = try chip.requestLine(22, .{ .output = true });
    defer line.close();
    while (true) {
        try line.setHigh();
        io.sleep(.fromSeconds(1), .awake) catch {};
        try line.setLow();
        io.sleep(.fromSeconds(1), .awake) catch {};
    }
}
