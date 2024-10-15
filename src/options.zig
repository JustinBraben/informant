const Options = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const builtin = @import("builtin");

const Cli = @import("cli.zig");

allocator: Allocator,

/// Number of warmup runs
warmup_count: u64 = 0,
/// What color mode to use for the terminal output
output_style: OutputStyleOption = .Full,

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

pub fn from_cli_arguments(allocator: Allocator, cli_args: Cli) !Options {
    return .{
        .allocator = allocator,
        .warmup_count = cli_args.warmup,
        .output_style = cli_args.style,
    };
}

pub fn deinit(self: *Options) void {
    _ = &self;
}
