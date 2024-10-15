const Commands = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const builtin = @import("builtin");

const Cli = @import("cli.zig");

pub const Command = struct {
    name: []const u8,
    parameters: []const []const u8,
};

allocator: Allocator,
command_list: ArrayList(Command),

pub fn from_cli_arguments(allocator: Allocator, cli_args: Cli) !Commands {
    _ = cli_args;
    var command_list = ArrayList(Command).init(allocator);
    const command_name = "run-this";
    const command_parameters: []const []const u8 = &.{ "arg1", "arg2" };
    try command_list.append(.{
        .name = try allocator.dupe(u8, command_name),
        .parameters = try allocator.dupe([]const u8, command_parameters),
    });

    return .{
        .allocator = allocator,
        .command_list = command_list,
    };
}

pub fn deinit(self: *Commands) void {
    for (self.command_list.items) |item| {
        self.allocator.free(item.name);
        self.allocator.free(item.parameters);
    }
    self.command_list.deinit();
}

/// Helper function to print out Commands
pub fn print_members(self: *Commands) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (self.command_list.items) |command| {
        try stdout.print("name: {s}\n", .{command.name});

        for (command.parameters) |parameter| {
            try stdout.print("\tparam: {s}\n", .{parameter});
        }
    }

    try bw.flush(); // don't forget to flush!
}
