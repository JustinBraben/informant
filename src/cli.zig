const std = @import("std");
const io = std.io;
const mem = std.mem;
const Allocator = mem.Allocator;
const builtin = @import("builtin");
const clap = @import("clap");

const Cli = @This();

allocator: Allocator,

warmup: usize = 0,
help: bool = false,
version: bool = false,

pub fn parse_args(ally: Allocator) !Cli {
    const params = comptime clap.parseParamsComptime(
        \\-w, --warmup <NUM>        Perform NUM warmup runs before the actual benchmark. This can be used to fill
        \\                          (disk) caches for I/O-heavy programs.
        \\-h, --help                Print this help message and exit.
        \\-V, --version             Show version information.
        \\
    );

    const parsers = comptime .{
        .NUM = clap.parsers.int(usize, 10),
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = ally,
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // Write help if -h was passed
    if (res.args.help != 0) {
        try clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    return .{
        .allocator = ally,
        .warmup = if (res.args.warmup) |w| w else 0,
        .help = res.args.help != 0,
        .version = res.args.version != 0,
    };
}

pub fn deinit(self: *Cli) void {
    _ = &self;
}

pub fn print_args(self: *Cli) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    inline for (std.meta.fields(@TypeOf(self.*))) |f| {
        try stdout.print(f.name ++ ": {any}\n", .{@as(f.type, @field(self.*, f.name))});
    }

    try bw.flush(); // don't forget to flush!
}