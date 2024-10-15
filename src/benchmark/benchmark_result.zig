const BenchmarkResult = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const builtin = @import("builtin");

const ExportManager = @import("../export/export_manager.zig");
const TimeUnit = ExportManager.TimeUnit;

allocator: Allocator,
/// The full command line of the program that is being benchmarked
command: []const u8,
/// The full command line of the program that is being benchmarked, possibly including a list of
/// parameters that were not used in the command line template.
command_with_unused_parameters: []const u8,
/// The average run time
mean: TimeUnit,
/// The standard deviation of all run times. Not available if only one run has been performed
stddev: TimeUnit,
/// The median run time
median: TimeUnit,
/// Time spent in user mode
user: TimeUnit,
/// Time spent in kernel mode
system: TimeUnit,
/// Minimum of all measured times
min: TimeUnit,
/// Maximum of all measured times
max: TimeUnit,
/// All run time measurements
times: ArrayList(TimeUnit),
/// Exit codes of all command invocations
exit_codes: ArrayList(i32),
/// Parameter values for this benchmark
parameters: StringHashMap([]const u8),
