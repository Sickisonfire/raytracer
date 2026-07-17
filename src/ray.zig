const std = @import("std");
const math = @import("math.zig");
const Hittable = @import("hittable.zig");

const Point3 = math.Point3;
const Vec3 = math.Vec3;
const Color = math.Color;
const Sphere = Hittable.Sphere;
const HittableList = Hittable.List;
const HitRecord = Hittable.Record;

pub const Ray = @This();

origin: Point3,
direction: Vec3,
hit_record: HitRecord,
prng_source: *std.Random,

pub fn new(origin: Point3, direction: *const Vec3, prng: *std.Random) Ray {
    return Ray{ .origin = origin, .direction = direction.*, .hit_record = .new(), .prng_source = prng };
}

pub fn at(self: *Ray, t: f64) Point3 {
    return self.direction.multScalar(t).add(&self.origin);
}

pub fn getColor(self: *Ray, hittable: Hittable, depth: u32) Color {
    var hr = &self.hit_record;
    if (depth <= 0) return Color.new(0, 0, 0);
    if (hittable.item.hit(self, .interval(0.001, std.math.inf(f64)))) {
        const direction = Vec3.randomUnitVector(self.prng_source).add(&hr.normal);

        var r: Ray = .new(hr.p, &direction, self.prng_source);
        return r.getColor(hittable, depth - 1).multScalar(0.5);
    }

    const unit_dir = self.direction.unitVector();
    // lerp
    // start_color + (end_color - start_color)a
    const a = 0.5 * (unit_dir.y() + 1.0);
    const start_color: Color = .new(1.0, 1.0, 1.0);
    const end_color: Color = .new(0.5, 0.7, 1.0);

    return start_color.add(&end_color.sub(&start_color).multScalar(a));
}

test "at" {
    const direction = Vec3{ .inner = .{ 1, 2, 3 } };
    var ray: Ray = .new(.zero, &direction);

    const actual = ray.at(2);

    const expected = Point3{ .inner = .{ 2, 4, 6 } };
    try std.testing.expectEqual(expected, actual);
}
