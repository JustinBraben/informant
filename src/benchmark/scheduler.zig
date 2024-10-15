const Scheduler = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const builtin = @import("builtin");

const BenchmarkResult = @import("benchmark_result.zig");
const Commands = @import("../commands.zig");
const ExportManager = @import("../export/export_manager.zig");
const Options = @import("../options.zig");

allocator: Allocator,
commands: *Commands,
options: *Options,
export_manager: *ExportManager,
results: ArrayList(BenchmarkResult),

pub fn init(allocator: Allocator, commands: *Commands, options: *Options, export_manager: *ExportManager) !Scheduler {
    return .{
        .allocator = allocator,
        .commands = commands,
        .options = options,
        .export_manager = export_manager,
        .results = ArrayList(BenchmarkResult).init(allocator),
    };
}

pub fn deinit(self: *Scheduler) void {
    self.results.deinit();
}

pub fn final_export(self: *Scheduler) !void {
    try self.export_manager.write_results();

    // TODO:
    // self.export_manager.write_results(&self.results, self.options.sort_order_exports, false);
}
