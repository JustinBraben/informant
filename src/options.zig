const Options = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const builtin = @import("builtin");

const Cli = @import("cli.zig");
const Commands = @import("commands.zig");

const DEFAULT_SHELL_WINDOWS: []const u8 = "powershell";
const DEFAULT_SHELL: []const u8 = if (builtin.target.os.tag == .windows) DEFAULT_SHELL_WINDOWS else "sh";

pub const Shell = struct {
    default: []const u8 = DEFAULT_SHELL,
};

pub const OutputStyleOption = enum {
    /// Do not output with colors or any special formatting
    Basic,
    /// Output with full color and formatting
    Full,
    /// Keep elements such as progress bar, but use no coloring
    NoColor,
    /// Keep coloring, but use no progress bar
    Color,
    /// Disable all the output
    Disabled,
};

pub const SortOrder = enum {
    Command,
    MeanTime,
};

/// Bounds for the number of benchmark runs
pub const RunBounds = struct {
    /// Minimum number of benchmark runs
    min: u64,
    /// Maximum number of benchmark runs
    max: ?u64,
};

// Members

allocator: Allocator,
/// Number of warmup runs
warmup_count: u64 = 0,
/// What color mode to use for the terminal output
output_style: OutputStyleOption = .Full,
/// How to order benchmarks in the relative speed comparison
sort_order_speed_comparison: SortOrder = .MeanTime,
/// How to order benchmarks in the markup format exports
sort_order_exports: SortOrder = .Command,

pub fn from_cli_arguments(allocator: Allocator, cli_args: Cli) !Options {
    return .{
        .allocator = allocator,
        .warmup_count = cli_args.warmup,
        .output_style = cli_args.style,
        .sort_order_speed_comparison = .MeanTime,
        .sort_order_exports = .Command,
    };
}

pub fn deinit(self: *Options) void {
    _ = &self;
}

pub fn validate_against_command_list(self: *Options, commands: *Commands) !void {
    _ = &self;
    _ = &commands;
}

/// Helper function to print out options
pub fn print_members(self: *Options) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    inline for (std.meta.fields(@TypeOf(self.*))) |f| {
        try stdout.print(f.name ++ ": {any}\n", .{@as(f.type, @field(self.*, f.name))});
    }

    try bw.flush(); // don't forget to flush!
}
