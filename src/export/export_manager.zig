const ExportManager = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const builtin = @import("builtin");

const BenchmarkResult = @import("../benchmark/benchmark_result.zig");
const Cli = @import("../cli.zig");

pub const TimeUnit = enum {
    Millisecond,
    Second,
};

pub const ExportTarget = enum {
    File,
    Stdout,
};

allocator: Allocator,
time_unit: TimeUnit,

pub fn from_cli_arguments(allocator: Allocator, cli_args: Cli) !ExportManager {
    return .{
        .allocator = allocator,
        .time_unit = cli_args.time_unit,
    };
}

pub fn deinit(self: *ExportManager) void {
    _ = &self;
}

pub fn write_results(self: *ExportManager) !void {
    _ = &self;
}

// TODO:
// pub fn write_results(self: *ExportManager, results: *ArrayList(BenchmarkResult), sort_order: SortOrder, false) !void {
//     _ = &self;
// }

/// Helper function to print out options
pub fn print_members(self: *ExportManager) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    inline for (std.meta.fields(@TypeOf(self.*))) |f| {
        try stdout.print(f.name ++ ": {any}\n", .{@as(f.type, @field(self.*, f.name))});
    }

    try bw.flush(); // don't forget to flush!
}
