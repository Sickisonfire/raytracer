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
    var start_color: Color = .new(1.0, 1.0, 1.0);
    var end_color: Color = .new(0.5, 0.7, 1.0);

    const ret = start_color.add(&end_color.sub(&start_color).multScalar(a));
    // end_color.sub(start_color);
    // end_color.multScalar(a);
    // start_color.add(end_color);

    // const x = unit_dir.x();
    // std.debug.print("{any}", .{unit_dir});

    if (hitSphere(.new(0, 0, -1), 0.5, self)) {
        return .new(1, 0, 0);
    }

    return ret;
}

fn hitSphere(center: Point3, radius: f64, ray: *Ray) bool {
    var oc = &center.sub(&ray.origin);
    // oc.sub(ray.origin);
    const a = ray.direction.dot(&ray.direction);
    const b = ray.direction.dot(oc) * -2;
    const c = oc.dot(oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;

    return (discriminant >= 0);
}

test "at" {
    const direction = Vec3{ .inner = .{ 1, 2, 3 } };
    var ray: Ray = .new(.zero, direction);

    const actual = ray.at(2);

    const expected = Point3{ .inner = .{ 2, 4, 6 } };
    try std.testing.expectEqual(expected, actual);
}
