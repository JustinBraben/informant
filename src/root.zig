const std = @import("std");
const windows = std.os.windows;
const HANDLE = windows.HANDLE;
const FILETIME = windows.FILETIME;

fn processTimeToNanos(ft: FILETIME) i128 {
    // Convert to 100-nanosecond intervals (FILETIME format)
    const hns = (@as(i64, ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
    // Convert to nanoseconds by multiplying by 100
    // No epoch adjustment needed for process times
    return @as(i128, hns) * 100;
}

pub fn printProcessTimes_old() !void {
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

    // creation_time is an actual timestamp, so we use fileTimeToNanoSeconds
    std.debug.print("creation_time: {d} ns\n", .{windows.fileTimeToNanoSeconds(creation_time)});

    // For process times (user and kernel), we use our direct conversion
    const user_ns = processTimeToNanos(user_time);
    const kernel_ns = processTimeToNanos(kernel_time);

    std.debug.print("Raw User Time: dwHighDateTime: {d}, dwLowDateTime: {d}\n", .{user_time.dwHighDateTime, user_time.dwLowDateTime});
    std.debug.print("Raw Kernel Time: dwHighDateTime: {d}, dwLowDateTime: {d}\n", .{kernel_time.dwHighDateTime, kernel_time.dwLowDateTime});
    
    std.debug.print("User Time: {d} ns ({d:.3} ms)\n", .{ user_ns, @as(f64, @floatFromInt(user_ns)) / std.time.ns_per_ms });
    std.debug.print("Kernel Time: {d} ns ({d:.3} ms)\n", .{ kernel_ns, @as(f64, @floatFromInt(kernel_ns)) / std.time.ns_per_ms });
}

pub fn printProcessTimes() !void {
    const current_process = windows.GetCurrentProcess();
    
    var creation_time: FILETIME = undefined;
    var exit_time: FILETIME = undefined;
    var kernel_time: FILETIME = undefined;
    var user_time: FILETIME = undefined;

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

    const user_ns = processTimeToNanos(user_time);
    const kernel_ns = processTimeToNanos(kernel_time);
    
    std.debug.print("\nTiming Results:\n", .{});
    std.debug.print("User Time: {d:.3} ms\n", .{@as(f64, @floatFromInt(user_ns)) / std.time.ns_per_ms});
    std.debug.print("Kernel Time: {d:.3} ms\n", .{@as(f64, @floatFromInt(kernel_ns)) / std.time.ns_per_ms});
    std.debug.print("Total Time: {d:.3} ms\n", .{
        @as(f64, @floatFromInt(user_ns + kernel_ns)) / std.time.ns_per_ms
    });
}

// Function to do some file I/O to generate kernel time
fn doKernelWork() !void {
    // Create a temporary file
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var buf: [4096]u8 = undefined;
    var i: usize = 0;
    // Do multiple write operations to ensure measurable kernel time
    while (i < 1000) : (i += 1) {
        // Write and read operations to generate system calls
        var file = try tmp.dir.createFile("test.txt", .{ .read = true });
        defer file.close();
        
        // Write some data
        _ = try file.write(&buf);
        // Seek back to start
        try file.seekTo(0);
        // Read the data
        _ = try file.readAll(&buf);
    }
    std.debug.print("Kernel work done: {d}\n", .{i});
}


// Function to do CPU-intensive work for user time
fn doUserWork() void {
    var sum: u64 = 0;
    var i: u64 = 0;
    while (i < 100_000_000) : (i += 1) {
        sum +%= i * i;
    }
    std.debug.print("User work done: {d}\n", .{sum});
}

// Example usage
pub fn main() !void {
    std.debug.print("Starting work...\n", .{});
    
    // First do some CPU-intensive work (user time)
    std.debug.print("Doing user mode work...\n", .{});
    doUserWork();
    
    // Then do some I/O work (kernel time)
    std.debug.print("Doing kernel mode work...\n", .{});
    try doKernelWork();
    
    // Measure the times
    try printProcessTimes();
}