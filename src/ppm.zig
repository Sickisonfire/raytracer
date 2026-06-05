const std = @import("std");
const vec = @import("vector.zig");
const Vec3 = vec.Vec3;

pub fn write_ppm(io: std.Io, dir: std.Io.Dir, file_name: []const u8) !void {
    var f = try dir.createFile(io, file_name, .{});
    defer f.close(io);

    const w = 256.0;
    const h = 256.0;
    var buf: [1024]u8 = undefined;
    var writer = f.writer(io, &buf);
    var interface = &writer.interface;
    _ = try interface.write("P3\n");
    _ = try interface.print("{d} {d}\n", .{ w, h });
    _ = try interface.write("255\n");

    const progress = std.Progress.start(io, .{});
    defer progress.end();
    const node = progress.start("render to ppm", w * h);
    defer node.end();

    for (0..w) |i| {
        for (0..h) |j| {
            node.completeOne();

            const r: f32 = @as(f32, @floatFromInt(j)) / (w - 1);
            const g: f32 = @as(f32, @floatFromInt(i)) / (h - 1);
            const b: f32 = 0.0;

            var color = Vec3{ .inner = .{ r, g, b } };

            try Vec3.write_color(interface, &color);
        }
    }
    try writer.flush();
}
