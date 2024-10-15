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

allocator: Allocator,
number: usize,
command: *Commands,
options: *Options,

pub fn init(allocator: Allocator, commands: *Commands, options: *Options) !Benchmark {
    return .{
        .allocator = allocator,
        .commands = commands,
        .options = options,
    };
}

pub fn deinit(self: *Benchmark) void {
    _ = &self;
}
