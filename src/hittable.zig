const std = @import("std");
const math = @import("math.zig");
const ray = @import("ray.zig");
const mat = @import("material.zig");

const Vec3 = math.Vec3;
const Point3 = math.Point3;
const Ray = ray.Ray;
const Interval = math.Interval;
const Material = mat.Material;

pub const Hittable = struct {
    vtable: *const VTable,

    const VTable = struct {
        hit: *const fn (hittable: *Hittable, r: *Ray, ray_t: Interval) bool,
    };
};

pub const Record = struct {
    p: Point3 = .zero,
    normal: Vec3 = .zero,
    t: f64 = std.math.inf(f64),
    front_face: bool = false,
    material: *mat.Material = undefined,

    pub const default: Record = .{};

    fn setFaceNormal(self: *Record, r: *Ray, outward_normal: *const Vec3) void {
        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal.* else outward_normal.*.multScalar(-1);
    }
};
pub const List = struct {
    alloc: std.mem.Allocator,
    list: std.ArrayList(*Hittable) = .empty,
    hittable: Hittable,

    pub fn new(alloc: std.mem.Allocator) List {
        return .{
            .alloc = alloc,
            .hittable = .{
                .vtable = &.{
                    .hit = hit,
                },
            },
        };
    }

    pub fn deinit(self: *List) void {
        self.list.deinit(self.alloc);
    }

    pub fn append(self: *List, item: *Hittable) !void {
        try self.list.ensureTotalCapacity(self.alloc, 64);

        self.list.appendAssumeCapacity(item);
    }

    pub fn hit(hittable: *Hittable, r: *Ray, ray_t: Interval) bool {
        const self: *List = @fieldParentPtr("hittable", hittable);
        var hit_obj = false;
        var closest = ray_t.max;

        for (self.list.items) |h| {
            if (h.vtable.hit(h, r, .interval(ray_t.min, closest))) {
                hit_obj = true;
                closest = r.hit_record.t;
            }
        }

        return hit_obj;
    }
};
pub const Sphere = struct {
    center: Point3,
    radius: f64,
    material: *Material,
    hittable: Hittable,

    pub fn new(center: Point3, radius: f64, material: *Material) Sphere {
        return .{
            .center = center,
            .radius = @max(0, radius),
            .material = material,
            .hittable = .{
                .vtable = &.{
                    .hit = hit,
                },
            },
        };
    }
    pub fn hit(hittable: *Hittable, r: *Ray, ray_t: Interval) bool {
        const self: *Sphere = @alignCast(@fieldParentPtr("hittable", hittable));
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
        hr.material = self.material;

        return true;
    }
};
