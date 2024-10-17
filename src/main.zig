const std = @import("std");
const time = std.time;
const builtin = @import("builtin");
const testing = std.testing;
const Cli = @import("cli.zig");
const Options = @import("options.zig");
const Commands = @import("commands.zig");
const ExportManager = @import("export/export_manager.zig");
const Scheduler = @import("benchmark/scheduler.zig");
const windows = std.os.windows;
const HANDLE = windows.HANDLE;
const FILETIME = windows.FILETIME;
const native_os = builtin.os.tag;
const debug = std.debug;
const print = debug.print;

const TimeInfo = struct {
    real: i128,
    user: i128,
    system: i128,
};

fn getTimeInfo() !TimeInfo {

    switch (native_os) {
        .windows => {
            return try windowsProcessTimes();
        },
        else => {
            var rusage: std.posix.rusage = undefined;
            rusage = std.posix.getrusage(1);

            const real = time.nanoTimestamp();
            const user: i128 = @intCast(rusage.utime.tv_sec * 1_000_000_000 + rusage.utime.tv_usec * 1000);
            const system: i128 = @intCast(rusage.stime.tv_sec * 1_000_000_000 + rusage.stime.tv_usec * 1000);

            return .{
                .real = real,
                .user = user,
                .system = system,
            };
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var cli_arguments = try Cli.get_cli_arguments(allocator);
    defer cli_arguments.deinit();

    // If -h was passed help will be displayed
    // program will exit gracefully
    if (cli_arguments.help) return;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var commands = try Commands.from_cli_arguments(allocator, cli_arguments);
    defer commands.deinit();

    var results = std.ArrayList(TimeInfo).init(allocator);
    defer results.deinit();

    // Split the command string into separate arguments
    // var cmd_iter = std.mem.tokenize(u8, cli_arguments.command.?[0], " ");
    var cmd_args = std.ArrayList([]const u8).init(arena.allocator());

    // TODO: set up default shell properly
    if (native_os == .windows) {
        try cmd_args.append("cmd.exe");
    }

    for (commands.command_list.items) |command| {
        try cmd_args.append(command.expression);
        for (command.parameters.items) |param| {
            try cmd_args.append(param);
        }
    }

    for (0..cli_arguments.min_runs) |_| {
        const start_time = try getTimeInfo();

        _ = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = cmd_args.items,
        });

        const end_time = try getTimeInfo();

        try results.append(.{
            .real = end_time.real - start_time.real,
            .user = end_time.user - start_time.user,
            .system = end_time.system - start_time.system,
        });
    }

    for (results.items, 0..) |result, i| {
        try stdout.print(
            \\Run {d}:
            \\  Real time: {d} ns
            \\  User time: {d} ns
            \\  System time: {d} ns
            \\
            , .{i + 1, result.real, result.user, result.system});
    }

    try bw.flush();
}

/// dump cli info to window
fn dump() !void {
    const allocator = std.heap.c_allocator;

    var cli_arguments = try Cli.get_cli_arguments(allocator);
    defer cli_arguments.deinit();
    var options = try Options.from_cli_arguments(allocator, cli_arguments);
    defer options.deinit();
    var commands = try Commands.from_cli_arguments(allocator, cli_arguments);
    defer commands.deinit();
    var export_manager = try ExportManager.from_cli_arguments(allocator, cli_arguments);
    defer export_manager.deinit();

    // If -h was passed help will be displayed
    // program will exit gracefully
    if (cli_arguments.help) return;

    try cli_arguments.print_members();
    try options.print_members();
    try commands.print_members();
    try export_manager.print_members();
}

fn run_child_process_windows() !void {
    const allocator = std.heap.c_allocator;

    const res = try std.process.Child.run(.{
        .argv = &[_][]const u8{ "powershell", "echo", "hi" },
        .allocator = allocator,
    });

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("res: {s}\n", .{res.stdout});
    try bw.flush(); // don't forget to flush!
}

fn run_child_process_posix() !void {
    const allocator = std.heap.c_allocator;

    const res = try std.process.Child.run(.{
        .argv = &[_][]const u8{"ls"},
        .allocator = allocator,
    });

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("res: {s}\n", .{res.stdout});
    try bw.flush(); // don't forget to flush!
}

fn processTimeToNanos(ft: FILETIME) i128 {
    // Convert to 100-nanosecond intervals (FILETIME format)
    const hns = (@as(i64, ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
    // Convert to nanoseconds by multiplying by 100
    // No epoch adjustment needed for process times
    return @as(i128, hns) * 100;
}

fn windowsProcessTimes() !TimeInfo {
    const current_process = windows.GetCurrentProcess();
    
    var creation_time: FILETIME = undefined;
    var exit_time: FILETIME = undefined;
    var kernel_time: FILETIME = undefined;
    var user_time: FILETIME = undefined;

    // Get process timing information
    const success = windows.kernel32.GetProcessTimes(
        current_process,
        &creation_time,
        &exit_time,
        &kernel_time,
        &user_time,
    );

    if (success == 0) {
        return error.WindowsError;
    }

    // For process times (user and kernel), we use our direct conversion
    const user_ns = processTimeToNanos(user_time);
    const kernel_ns = processTimeToNanos(kernel_time);

    return .{
        .real = user_ns + kernel_ns,
        .user = user_ns,
        .system = kernel_ns,
    };
}