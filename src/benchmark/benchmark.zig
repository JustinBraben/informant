const Benchmark = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const builtin = @import("builtin");

const Commands = @import("../commands.zig");
const Command = Commands.Command;
const ExportManager = @import("../export/export_manager.zig");
const Options = @import("../options.zig");
const Shell = Options.Shell;
const BenchmarkResult = @import("benchmark_result.zig");

allocator: Allocator,
number: usize,
commands: *Commands,
options: *Options,

pub fn init(allocator: Allocator, number: usize, commands: *Commands, options: *Options) !Benchmark {
    return .{
        .allocator = allocator,
        .number = number,
        .commands = commands,
        .options = options,
    };
}

pub fn deinit(self: *Benchmark) void {
    _ = &self;
}

pub fn run(self: *Benchmark) !BenchmarkResult {
    var times_real = ArrayList(u64).init(self.allocator);
    defer times_real.deinit();
    // var times_user = ArrayList(u64).init(self.allocator);
    // defer times_user.deinit();
    // var times_system = ArrayList(u64).init(self.allocator);
    // defer times_system.deinit();

    const shell = Shell{};

    var min: u64 = std.math.maxInt(u64);
    var max: u64 = std.math.minInt(u64);

    var timer = try std.time.Timer.start();
    for (0..5) |_| {
        const command = self.commands.command_list.items[0];
        _ = try std.process.Child.run(.{
            .argv = &[_][]const u8{ shell.default, command.expression },
            .allocator = self.allocator,
        });
        const delta_time = timer.lap();
        min = @min(min, delta_time);
        max = @max(max, delta_time);
    }

    return .{
        .min = min,
        .max = max,
    };
}
