const Cli = @This();

const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const builtin = @import("builtin");

const Errors = @import("errors.zig");
const Options = @import("options.zig");
const OutputStyleOption = Options.OutputStyleOption;
const ExportManager = @import("export/export_manager.zig");
const TimeUnit = ExportManager.TimeUnit;
const clap = @import("clap");

allocator: Allocator,

warmup: usize = 0,
min_runs: usize = 10,
max_runs: usize = 0,
runs: usize = 0,
style: OutputStyleOption = .Full,
time_unit: TimeUnit = .Millisecond,
command_name: ?[]const u8 = null,
command: ?[]const []const u8 = null,
help: bool = false,
version: bool = false,

pub fn get_cli_arguments(allocator: Allocator) !Cli {
    const params = comptime clap.parseParamsComptime(
        \\-w, --warmup <NUM>                Perform NUM warmup runs before the actual benchmark. This can be used to fill
        \\                                  (disk) caches for I/O-heavy programs.
        \\-m, --min_runs <NUM>              Perform at least NUM runs for each command (default: 10).
        \\-M, --max_runs <NUM>              Perform at most NUM runs for each command. By default, there is no limit.
        \\-r, --runs <NUM>                  Perform exactly NUM runs for each command. If this option is not specified,
        \\                                  informant automatically determines the number of runs.
        \\-s, --style <OutputStyleOption>   Set output style type (default: Full). Set this to 'Basic' to disable output
        \\                                  coloring and interactive elements. Set it to 'Full' to enable all effects even
        \\                                  if no interactive terminal was detected. Set this to 'NoColor' to keep the
        \\                                  interactive output without any colors. Set this to 'Color' to keep the colors
        \\                                  without any interactive output. Set this to 'None' to disable all the output
        \\                                  of the tool.
        \\-u, --time_unit <TimeUnit>        Set the time unit to be used. Possible values: Millisecond, Second.
        \\-n, --command_name <NAME>         Give a meaningful name to a command
        \\-h, --help                        Print this help message and exit.
        \\-V, --version                     Show version information.
        \\<Command>...                      Command to benchmark
        \\
    );

    const parsers = comptime .{
        .NUM = clap.parsers.int(usize, 10),
        .OutputStyleOption = clap.parsers.enumeration(OutputStyleOption),
        .TimeUnit = clap.parsers.enumeration(TimeUnit),
        .NAME = clap.parsers.string,
        .Command = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var command_str_len: usize = 0;
    for (res.positionals) |_| {
        command_str_len +|= 1;
    }
    var command = try allocator.alloc([]const u8, command_str_len);
    for (res.positionals, 0..) |s, index| {
        command[index] = try allocator.dupe(u8, s);
    }

    // Write help if -h was passed
    if (res.args.help != 0) {
        try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
        // TODO: Fix hack to show help even when no <Command> is given
        if (command_str_len == 0) command_str_len += 1;
    }

    if (command_str_len < 1) {
        const stderr_file = std.io.getStdErr().writer();
        var bw = std.io.bufferedWriter(stderr_file);
        const stderr = bw.writer();

        try stderr.print(
            \\error: The following required arguments were not provided:
            \\    <command>... not specified
            \\
            \\USAGE:
            \\    zig build run -- [OPTIONS] <command>...
            \\
            \\For more information try --help
            \\
        , .{});
        try bw.flush(); // don't forget to flush!

        return Errors.ParameterScanError.CommandRequired;
    }

    return .{
        .allocator = allocator,
        .warmup = if (res.args.warmup) |w| w else 0,
        .min_runs = if (res.args.min_runs) |min_r| min_r else 10,
        .max_runs = if (res.args.max_runs) |max_r| max_r else 0,
        .runs = if (res.args.runs) |r| r else 0,
        .style = if (res.args.style) |s| s else .Full,
        .time_unit = if (res.args.time_unit) |ts| ts else .Millisecond,
        .command_name = if (res.args.command_name) |s| try allocator.dupe(u8, s) else null,
        .command = if (command_str_len != 0) command else null,
        .help = res.args.help != 0,
        .version = res.args.version != 0,
    };
}

pub fn deinit(self: *Cli) void {
    if (self.command_name) |cn| self.allocator.free(cn);

    if (self.command) |command| {
        for (command) |cmd| {
            self.allocator.free(cmd);
        }
        self.allocator.free(command);
    }
}

/// Helper function to print out arguments made through Cli
pub fn print_members(self: *Cli) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    inline for (std.meta.fields(@TypeOf(self.*))) |f| {
        try stdout.print(f.name ++ ": {any}\n", .{@as(f.type, @field(self.*, f.name))});
    }

    try bw.flush(); // don't forget to flush!
}
