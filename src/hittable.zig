const std = @import("std");
const math = @import("math.zig");
const ray = @import("ray.zig");

const Vec3 = math.Vec3;
const Point3 = math.Point3;
const Ray = ray.Ray;
const Interval = math.Interval;

const Hittable = @This();

item: Item,

pub fn new(item: Item) Hittable {
    return .{ .item = item };
}

pub const Record = struct {
    p: Point3 = .zero,
    normal: Vec3 = .zero,
    t: f64 = std.math.inf(f64),
    front_face: bool = false,

    pub fn new() Record {
        return .{};
    }

    fn setFaceNormal(self: *Record, r: *Ray, outward_normal: *const Vec3) void {
        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal.* else outward_normal.*.multScalar(-1);
    }
};
pub const Item = union(enum) {
    sphere: Sphere,
    list: List,

    pub fn hit(self: Item, r: *Ray, ray_t: Interval) bool {
        return switch (self) {
            inline else => |v| v.hit(r, ray_t),
        };
    }
};

pub const List = struct {
    alloc: std.mem.Allocator,
    list: std.ArrayList(*Item) = .empty,

    pub fn new(alloc: std.mem.Allocator) List {
        return .{
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *List) void {
        self.list.deinit(self.alloc);
    }

    pub fn append(self: *List, item: *Item) !void {
        try self.list.ensureTotalCapacity(self.alloc, 64);

        self.list.appendAssumeCapacity(item);
    }

    pub fn hit(self: List, r: *Ray, ray_t: Interval) bool {
        var hit_obj = false;
        var closest = ray_t.max;

        for (self.list.items) |hittable| {
            if (hittable.hit(r, .interval(ray_t.min, closest))) {
                hit_obj = true;
                closest = r.hit_record.t;
            }
        }

        return hit_obj;
    }
};
pub const Sphere = struct {
    const Self = @This();
    center: Point3,
    radius: f64,

    pub fn new(center: Point3, radius: f64) Sphere {
        return .{
            .center = center,
            .radius = @max(0, radius),
        };
    }
    pub fn hit(self: Sphere, r: *Ray, ray_t: Interval) bool {
        var hr = &r.hit_record;
        const oc: Vec3 = self.center.sub(&r.origin);
        const a: f64 = r.direction.lengthSquared();
        const h: f64 = r.direction.dot(&oc);
        const c: f64 = oc.lengthSquared() - self.radius * self.radius;
        const discriminant: f64 = h * h - a * c;

        if (discriminant < 0) {
            return false;
        }

        const sqrt = @sqrt(discriminant);

        var root = (h - sqrt) / a;

        if (!ray_t.surrounds(root)) {
            root = (h + sqrt) / a;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        // record is only mutated on hit
        hr.t = root;
        hr.p = r.at(hr.t);
        const outward_normal = hr.p.sub(&self.center).divScalar(self.radius);
        hr.setFaceNormal(r, &outward_normal);

        return true;
    }
};
