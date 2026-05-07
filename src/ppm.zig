const std = @import("std");

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

    for (0..w) |i| {
        for (0..h) |j| {
            const r: f32 = @as(f32, @floatFromInt(j)) / (w - 1);
            const g: f32 = @as(f32, @floatFromInt(i)) / (h - 1);
            const b: f32 = 0.0;

            const ir: u32 = @intFromFloat(255.999 * r);
            const ig: u32 = @intFromFloat(255.999 * g);
            const ib: u32 = @intFromFloat(255.999 * b);
            var row_buf: [128]u8 = undefined;
            const pix = try std.fmt.bufPrint(&row_buf, "{d} {d} {d}\n", .{ ir, ig, ib });
            _ = try interface.write(pix);
        }
    }
    try writer.flush();
}
