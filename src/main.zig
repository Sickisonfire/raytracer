const std = @import("std");
const math = @import("math.zig");
const Ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const Camera = @import("camera.zig");
const mat = @import("material.zig");
const Vec3 = math.Vec3;
const Io = std.Io;
const Sphere = hittable.Sphere;
const List = hittable.List;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    defer _ = init.arena.reset(.free_all);
    const io = init.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out", .{});
    defer dir.close(io);

    var xoshiro = std.Random.DefaultPrng.init(1234);
    var rng = xoshiro.random();

    var mat_ground: mat.Lambert = .new(math.Color.new(0.8, 0.8, 0.0));
    var mat_center: mat.Lambert = .new(math.Color.new(0.1, 0.2, 0.5));
    var mat_left: mat.Metal = .new(math.Color.new(0.8, 0.8, 0.8), 0.3);
    var mat_right: mat.Metal = .new(math.Color.new(0.8, 0.6, 0.2), 1);

    var sp_center: Sphere = .new(.new(0, 0, -1.2), 0.5, &mat_center.interface);
    var sp_left: Sphere = .new(.new(-1, 0, -1.0), 0.5, &mat_left.interface);
    var sp_right: Sphere = .new(.new(1, 0, -1.0), 0.5, &mat_right.interface);
    var sp_ground: Sphere = .new(.new(0, -100.5, -1), 100, &mat_ground.interface);

    var world_list: List = .new(arena);
    defer world_list.deinit();

    try world_list.append(&sp_ground.hittable);
    try world_list.append(&sp_center.hittable);
    try world_list.append(&sp_left.hittable);
    try world_list.append(&sp_right.hittable);

    var camera: Camera = .init(.zero, 400, 16.0 / 9.0, 1.0, &rng, 100, 50);
    try camera.renderToFile(&world_list.hittable, io, dir, "out.ppm");
}
