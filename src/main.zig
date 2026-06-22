const std = @import("std");
const ppm = @import("ppm.zig");
const vec = @import("vector.zig");
const Ray = @import("ray.zig");
const Vec3 = vec.Vec3;
const Io = std.Io;

const Camera = struct {
    center: vec.Point3,
    focal_length: f64,

    pub fn init(center: vec.Point3, focal_length: f64) Camera {
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

    pub fn init(image: Image) Viewport {
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
        const delta_u = blk: {
            var du = viewport_u;
            du.divScalar(@floatFromInt(self.image.width));
            break :blk du;
        };

        // viewport y vector
        const viewport_v: Vec3 = .new(0, -self.height, 0);
        // viewport y segment length
        const delta_v = blk: {
            var dv = viewport_v;
            dv.divScalar(@floatFromInt(self.image.height));
            break :blk dv;
        };
        // top left (0,0) vector from camera center
        const viewport_top_left = blk: {
            var v = cam.center;
            var vu = viewport_u;
            vu.divScalar(2);
            var vv = viewport_v;
            vv.divScalar(2);
            const vc: Vec3 = .new(0, 0, cam.focal_length);
            v.sub(vc);
            v.sub(vu);
            v.sub(vv);
            break :blk v;
        };

        // offset to find the "center" of the pixel
        const pixel_0_0 = blk: {
            var v = viewport_top_left;
            var delta_uv = delta_u;
            delta_uv.add(delta_v);
            delta_uv.divScalar(2);

            v.add(delta_uv);
            break :blk v;
        };

        for (0..h) |i| {
            for (0..w) |j| {
                node.completeOne();

                var px_loc = blk: {
                    var p = pixel_0_0;
                    var dx = delta_u;
                    dx.multScalar(@floatFromInt(j));
                    var dy = delta_v;
                    dy.multScalar(@floatFromInt(i));
                    p.add(dx);
                    p.add(dy);
                    break :blk p;
                };

                px_loc.sub(cam.center);
                var ray: Ray = .new(cam.center, px_loc);

                const color = ray.getColor();

                try Vec3.write_color(interface, &color);
            }
        }
        try writer.flush();
    }
};
pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    _ = arena;
    const io = init.io;
    const dir = try std.Io.Dir.cwd().openDir(io, "zig-out", .{});

    const image: Image = .init(400, 16.0 / 9.0);

    var viewport: Viewport = .init(image);
    const camera: Camera = .init(.zero, 1.0);

    try viewport.write_ppm(camera, io, dir, "out.ppm");
}
