const std = @import("std");
const vec = @import("vector.zig");

const Point3 = vec.Point3;
const Vec3 = vec.Vec3;
const Color = vec.Color;

const Ray = @This();

origin: Point3,
direction: Vec3,

pub fn new(origin: Point3, direction: *const Vec3) Ray {
    return Ray{ .origin = origin, .direction = direction.* };
}

pub fn at(self: *Ray, t: f64) Point3 {
    return self.direction.multScalar(t).add(&self.origin);
}

pub fn getColor(self: *Ray) Color {
    const unit_dir = self.direction.unitVector();
    // lerp
    // start_color + (end_color - start_color)a
    const a = 0.5 * (unit_dir.y() + 1.0);
    const t = hitSphere(.new(0, 0, -1), 0.5, self);

    if (t > 0) {
        const n: Vec3 = Vec3.unitVector(&self.at(t).sub(&.new(0, 0, -1)));
        return Vec3.new(n.x() + 1, n.y() + 1, n.z() + 1).multScalar(0.5);
    }
    const start_color: Color = .new(1.0, 1.0, 1.0);
    const end_color: Color = .new(0.5, 0.7, 1.0);
    const ret = start_color.add(&end_color.sub(&start_color).multScalar(a));

    return ret;
}

fn hitSphere(center: Point3, radius: f64, ray: *Ray) f64 {
    const oc: Vec3 = center.sub(&ray.origin);
    const a: f64 = ray.direction.lengthSquared();
    const h: f64 = ray.direction.dot(&oc);
    const c: f64 = oc.lengthSquared() - radius * radius;
    const discriminant: f64 = h * h - a * c;

    if (discriminant < 0) {
        return -1.0;
    } else {
        return (h - std.math.sqrt(discriminant)) / a;
    }
}

test "at" {
    const direction = Vec3{ .inner = .{ 1, 2, 3 } };
    var ray: Ray = .new(.zero, &direction);

    const actual = ray.at(2);

    const expected = Point3{ .inner = .{ 2, 4, 6 } };
    try std.testing.expectEqual(expected, actual);
}
