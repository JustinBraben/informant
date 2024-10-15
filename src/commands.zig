const Commands = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const builtin = @import("builtin");

const Cli = @import("cli.zig");

pub const Command = struct {
    allocator: Allocator,
    /// The command name (without parameter substitution)
    name: ?[]const u8 = null,
    /// The command that should be executed (without parameter substitution)
    expression: []const u8,
    /// Zero or more parameter values.
    parameters: ?[]const []const u8 = null,

    pub fn init(allocator: Allocator, name: ?[]const u8, expression: []const u8) !Command {
        return .{
            .allocator = allocator,
            .name = if (name) |str| try allocator.dupe(u8, str) else null,
            .expression = try allocator.dupe(u8, expression),
            .parameters = null,
        };
    }

    pub fn init_parametrized(
        allocator: Allocator,
        name: ?[]const u8,
        expression: []const u8,
        parameters: ?[]const []const u8,
    ) !Command {
        return .{
            .allocator = allocator,
            .name = if (name) |str| try allocator.dupe(u8, str) else null,
            .expression = try allocator.dupe(u8, expression),
            .parameters = if (parameters) |params| try allocator.dupe([]const u8, params) else null,
        };
    }

    pub fn deinit(self: *Command) void {
        if (self.name) |_| {
            self.allocator.free(self.name);
        }

        self.allocator.free(self.expression);

        if (self.parameters) |_| {
            self.allocator.free(self.parameters);
        }
    }
};

allocator: Allocator,
command_list: ArrayList(Command),

pub fn from_cli_arguments(allocator: Allocator, cli_args: Cli) !Commands {
    // _ = cli_args;
    // var command_list = ArrayList(Command).init(allocator);
    // const command_name = "some-command";
    // const command_expression = "Get-Child";
    // const command_parameters: []const []const u8 = &.{ "arg1", "arg2" };
    // try command_list.append(try Command.init_parametrized(allocator, command_name, command_expression, command_parameters));

    var command_list = ArrayList(Command).init(allocator);
    if (cli_args.command) |command| {
        for (command) |cmd| {
            try command_list.append(try Command.init_parametrized(allocator, null, cmd, null));
        }
    }

    return .{
        .allocator = allocator,
        .command_list = command_list,
    };
}

pub fn deinit(self: *Commands) void {
    // var current = self.command_list.popOrNull();
    // while (current) |_| {
    //     current.?.deinit();
    //     current = self.command_list.popOrNull();
    // }
    // for (self.command_list.items) |item| {
    //     item.deinit();
    // }
    for (self.command_list.items) |item| {
        if (item.name) |nm| {
            self.allocator.free(nm);
        }
        self.allocator.free(item.expression);

        if (item.parameters) |params| {
            self.allocator.free(params);
        }
    }
    self.command_list.deinit();
}

pub fn num_commands(self: *Commands) usize {
    return self.command_list.items.len;
}

/// Helper function to print out Commands
pub fn print_members(self: *Commands) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (self.command_list.items) |command| {
        try stdout.print("name: {?s}\n", .{command.name});

        try stdout.print("expression: {s}\n", .{command.expression});

        if (command.parameters) |parameters| {
            for (parameters) |param| {
                try stdout.print("\tparam: {?s}\n", .{param});
            }
        } else {
            try stdout.print("\tparam: {?}\n", .{null});
        }
    }

    try bw.flush(); // don't forget to flush!
}
