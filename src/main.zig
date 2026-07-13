const std = @import("std");
const math = @import("math.zig");
const Ray = @import("ray.zig");
const Hittable = @import("hittable.zig");
const Camera = @import("camera.zig");
const Vec3 = math.Vec3;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    defer _ = init.arena.reset(.free_all);
    const io = init.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out", .{});
    defer dir.close(io);

    var xoshiro = std.Random.DefaultPrng.init(1234);
    var rng = xoshiro.random();

    var h1 = Hittable.Item{ .sphere = .new(.new(0, 0, -1), 0.5) };
    var h2 = Hittable.Item{ .sphere = .new(.new(0, -100.5, -1), 100) };

    var world_list: Hittable.List = .new(arena);
    defer world_list.deinit();

    try world_list.append(&h1);
    try world_list.append(&h2);
    const world: Hittable = .new(.{ .list = world_list });

    var camera: Camera = .init(.zero, 400, 16.0 / 9.0, 1.0, &rng, 100, 50);
    try camera.renderToFile(world, io, dir, "out.ppm");
}
