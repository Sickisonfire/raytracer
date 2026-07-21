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
    fuzz: f64,
    interface: Material,
    pub fn new(albedo: Color, fuzz: f64) Metal {
        return .{
            .fuzz = if (fuzz < 1) fuzz else 1,
            .interface = .{
                .albedo = albedo,
                .vtable = &.{
                    .scatter = scatter,
                },
            },
        };
    }

    pub fn scatter(mat: *Material, ray_in: Ray, attenuation: *Color) ?Ray {
        const self: *Metal = @alignCast(@fieldParentPtr("interface", mat));
        const n = ray_in.hit_record.normal;
        const len = ray_in.direction.dot(&n);
        const reflected = ray_in.direction.sub(&n.multScalar(len).multScalar(2));
        const v_fuzz = Vec3.randomUnitVector(ray_in.prng_source).multScalar(self.fuzz);
        const direction = reflected.unitVector().add(&v_fuzz);

        attenuation.* = mat.albedo;
        if (direction.dot(&ray_in.hit_record.normal) > 0) {
            return .new(ray_in.hit_record.p, &direction, ray_in.prng_source);
        }

        return null;
    }
};
