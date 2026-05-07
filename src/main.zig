const std = @import("std");
const ppm = @import("ppm.zig");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    _ = arena;
    const io = init.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out", .{});

    try ppm.write_ppm(io, dir, "out.ppm");
}
