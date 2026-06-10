const std = @import("std");
const vec = @import("vector.zig");

const Point3 = vec.Point3;
const Vec3 = vec.Vec3;

const Ray = @This();

origin: Point3,
direction: Vec3,

fn new(origin: Point3, direction: Vec3) Ray {
    return Ray{ .origin = origin, .direction = direction };
}

fn at(self: *Ray, t: f64) Point3 {
    var ret = self.direction;
    _ = ret.multScalar(t).add(&self.origin);

    return ret;
}

test "at" {
    const direction = Vec3{ .inner = .{ 1, 2, 3 } };
    var ray: Ray = .new(.zero, direction);

    const actual = ray.at(2);

    const expected = Point3{ .inner = .{ 2, 4, 6 } };
    try std.testing.expectEqual(expected, actual);
}
