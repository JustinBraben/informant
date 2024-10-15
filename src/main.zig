const std = @import("std");
const Cli = @import("cli.zig");
const debug = std.debug;
const print = debug.print;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var cli = try Cli.parse_args(allocator);
    defer cli.deinit();

    // If -h was passed help will be displayed
    // program will exit gracefully
    if (cli.help) return;

    try cli.print_args();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
