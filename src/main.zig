const std = @import("std");
const math = @import("math.zig");
const Ray = @import("ray.zig");
const Hittable = @import("hittable.zig");
const Vec3 = math.Vec3;
const Io = std.Io;

const Camera = struct {
    center: math.Point3,
    focal_length: f64,

    pub fn init(center: math.Point3, focal_length: f64) Camera {
        return Camera{
            .center = center,
            .focal_length = focal_length,
        };
    }
};
const Image = struct {
    width: u32,
    height: u32,
    aspect: f64,

    pub fn init(width: u32, aspect_ratio: f64) Image {
        const height = blk: {
            var h: u32 = @trunc(width / aspect_ratio);
            h = if (h < 1) 1 else h;
            break :blk h;
        };

        return Image{
            .width = width,
            .height = height,
            .aspect = aspect_ratio,
        };
    }
};
const Viewport = struct {
    width: f64,
    height: f64,
    image: Image,
    world: *Hittable.Item,

    pub fn init(image: Image, world: *Hittable.Item) Viewport {
        const viewport_height = 2.0;
        const viewport_width = blk: {
            const w: f64 = @floatFromInt(image.width);
            const h: f64 = @floatFromInt(image.height);
            const r = viewport_height * w / h;
            break :blk r;
        };
        return Viewport{
            .width = viewport_width,
            .height = 2.0,
            .image = image,
            .world = world,
        };
    }
    pub fn write_ppm(self: *Viewport, cam: Camera, io: std.Io, dir: std.Io.Dir, file_name: []const u8) !void {
        var f = try dir.createFile(io, file_name, .{});
        defer f.close(io);

        const w = self.image.width;
        const h = self.image.height;
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

        // viewport x vector
        const viewport_u: Vec3 = .new(self.width, 0, 0);
        // viewport x segment length
        const delta_u: Vec3 = viewport_u.divScalar(@floatFromInt(self.image.width));

        // viewport y vector
        const viewport_v: Vec3 = .new(0, -self.height, 0);
        // viewport y segment length
        const delta_v = viewport_v.divScalar(@floatFromInt(self.image.height));
        // top left (0,0) vector from camera center

        const viewport_top_left = cam.center
            .sub(&.new(0, 0, cam.focal_length))
            .sub(&viewport_u.divScalar(2))
            .sub(&viewport_v.divScalar(2));

        // offset to find the "center" of the pixel
        const pixel_0_0 = &viewport_top_left
            .add(&delta_u.add(&delta_v).divScalar(2));

        for (0..h) |i| {
            for (0..w) |j| {
                node.completeOne();

                const px_loc = &pixel_0_0
                    .add(&delta_u.multScalar(@floatFromInt(j)))
                    .add(&delta_v.multScalar(@floatFromInt(i)))
                    .sub(&cam.center);

                var ray: Ray = .new(cam.center, px_loc);

                const color = ray.getColor(self.world);

                try Vec3.write_color(interface, &color);
            }
        }
        try writer.flush();
    }
};
pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    defer _ = init.arena.reset(.free_all);
    const io = init.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out", .{});

    const image: Image = .init(400, 16.0 / 9.0);

    var h1 = Hittable.Item{ .sphere = .new(.new(0, 0, -1), 0.5) };
    var h2 = Hittable.Item{ .sphere = .new(.new(0, -100.5, -1), 100) };

    var world_list: Hittable.List = .new(arena);
    defer world_list.deinit();

    try world_list.append(&h1);
    try world_list.append(&h2);
    var world = Hittable.Item{ .list = world_list };

    var viewport: Viewport = .init(image, &world);
    const camera: Camera = .init(.zero, 1.0);

    try viewport.write_ppm(camera, io, dir, "out.ppm");
}
