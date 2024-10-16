const Scheduler = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const builtin = @import("builtin");

const Benchmark = @import("benchmark.zig");
const BenchmarkResult = @import("benchmark_result.zig");
const Commands = @import("../commands.zig");
const ExportManager = @import("../export/export_manager.zig");
const Options = @import("../options.zig");
const Shell = Options.Shell;

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

// TODO: Run commands and time how long they take
// Store the results in self.results
pub fn run_benchmarks(self: *Scheduler) !void {
    for (self.commands.command_list.items, 1..) |_, index| {
        for (0..5) |_| {
            var benchmark = try Benchmark.init(self.allocator, index, self.commands, self.options);
            defer benchmark.deinit();
            try self.results.append(try benchmark.run());
        }

        // const shell = Shell{};
        // const command = commands.expression;
        // const res = try std.process.Child.run(.{
        //     .argv = &[_][]const u8{ shell.default, command },
        //     .allocator = self.allocator,
        // });

        // const stdout_file = std.io.getStdOut().writer();
        // var bw = std.io.bufferedWriter(stdout_file);
        // const stdout = bw.writer();
        // try stdout.print("running command {s}: {s}\n", .{ command, res.stdout });
        // try bw.flush(); // don't forget to flush!
    }
}

pub fn final_export(self: *Scheduler) !void {
    try self.export_manager.write_results(&self.results, self.options.sort_order_exports, false);
}
