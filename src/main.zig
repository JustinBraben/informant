const std = @import("std");
const testing = std.testing;
const Cli = @import("cli.zig");
const Options = @import("options.zig");
const Commands = @import("commands.zig");
const ExportManager = @import("export/export_manager.zig");
const Scheduler = @import("benchmark/scheduler.zig");
const debug = std.debug;
const print = debug.print;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var cli_arguments = try Cli.get_cli_arguments(allocator);
    defer cli_arguments.deinit();

    // If -h was passed help will be displayed
    // program will exit gracefully
    if (cli_arguments.help) return;

    var options = try Options.from_cli_arguments(allocator, cli_arguments);
    defer options.deinit();
    var commands = try Commands.from_cli_arguments(allocator, cli_arguments);
    defer commands.deinit();
    var export_manager = try ExportManager.from_cli_arguments(allocator, cli_arguments);
    defer export_manager.deinit();

    try options.validate_against_command_list(&commands);

    var scheduler = try Scheduler.init(allocator, &commands, &options, &export_manager);
    defer scheduler.deinit();

    // try commands.print_members();

    try scheduler.run_benchmarks();
    // try scheduler.print_relative_speed_comparison();
    try scheduler.final_export();

    // try cli_arguments.print_members();
}

/// dump cli info to window
fn dump() !void {
    const allocator = std.heap.c_allocator;

    var cli_arguments = try Cli.get_cli_arguments(allocator);
    defer cli_arguments.deinit();
    var options = try Options.from_cli_arguments(allocator, cli_arguments);
    defer options.deinit();
    var commands = try Commands.from_cli_arguments(allocator, cli_arguments);
    defer commands.deinit();
    var export_manager = try ExportManager.from_cli_arguments(allocator, cli_arguments);
    defer export_manager.deinit();

    // If -h was passed help will be displayed
    // program will exit gracefully
    if (cli_arguments.help) return;

    try cli_arguments.print_members();
    try options.print_members();
    try commands.print_members();
    try export_manager.print_members();
}

fn run_child_process() !void {
    const allocator = std.heap.c_allocator;

    const res = try std.process.Child.run(.{
        .argv = &[_][]const u8{ "powershell", "echo", "hi" },
        .allocator = allocator,
    });

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("res: {s}\n", .{res.stdout});
    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
