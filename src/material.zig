const std = @import("std");
const r = @import("ray.zig");
const math = @import("math.zig");
const Ray = r.Ray;
const Color = math.Color;
const Vec3 = math.Vec3;

pub const Material = struct {
    albedo: Color,

    vtable: *const VTable,

    const VTable = struct {
        scatter: *const fn (self: *Material, ray: Ray, attenuation: *Color) ?Ray,
    };
};

pub const Lambert = struct {
    interface: Material,

    pub fn new(albedo: Color) Lambert {
        return .{
            .interface = .{
                .albedo = albedo,
                .vtable = &.{
                    .scatter = scatter,
                },
            },
        };
    }
    pub fn scatter(mat: *Material, ray: Ray, attenuation: *Color) ?Ray {
        const direction = blk: {
            var ret = Vec3.randomUnitVector(ray.prng_source).add(&ray.hit_record.normal);
            if (ret.nearZero()) {
                break :blk ray.hit_record.normal;
            }
            break :blk ret;
        };
        attenuation.* = mat.albedo;

        return .new(ray.hit_record.p, &direction, ray.prng_source);
    }
};

pub const Metal = struct {
    interface: Material,
    pub fn new(albedo: Color) Metal {
        return .{
            .interface = .{
                .albedo = albedo,
                .vtable = &.{
                    .scatter = scatter,
                },
            },
        };
    }

    pub fn scatter(mat: *Material, ray: Ray, attenuation: *Color) ?Ray {
        const n = ray.hit_record.normal;
        const len = ray.direction.dot(&n);

        const direction = ray.direction.sub(&n.multScalar(len).multScalar(2));
        attenuation.* = mat.albedo;

        return .new(ray.hit_record.p, &direction, ray.prng_source);
    }
};
