const std = @import("std");

pub const Point3 = Vec3;
pub const Color = Vec3;
// implementation inspired by mach
// https://github.com/hexops/mach/blob/main/src/math/vec.zig
pub const Vec3 = struct {
    inner: @Vector(3, f64),

    pub const zero = Vec3{ .inner = @splat(0) };

    pub fn new(x_: f64, y_: f64, z_: f64) Vec3 {
        return Vec3{ .inner = .{ x_, y_, z_ } };
    }

    pub fn add(self: *const Vec3, other: *const Vec3) Vec3 {
        return .{ .inner = self.inner + other.inner };
    }

    pub fn sub(self: *const Vec3, other: *const Vec3) Vec3 {
        return .{ .inner = self.inner - other.inner };
    }

    pub fn multScalar(self: *const Vec3, t: f64) Vec3 {
        return .{ .inner = self.inner * Vec3.splat(t).inner };
    }

    pub fn divScalar(self: *const Vec3, t: f64) Vec3 {
        return .{ .inner = self.inner / Vec3.splat(t).inner };
    }

    pub fn splat(s: f64) Vec3 {
        return .{ .inner = @splat(s) };
    }

    pub fn x(self: *const Vec3) f64 {
        return self.inner[0];
    }
    pub fn y(self: *const Vec3) f64 {
        return self.inner[1];
    }
    pub fn z(self: *const Vec3) f64 {
        return self.inner[2];
    }

    pub fn r(self: *const Vec3) f64 {
        return self.inner[0];
    }
    pub fn g(self: *const Vec3) f64 {
        return self.inner[1];
    }
    pub fn b(self: *const Vec3) f64 {
        return self.inner[2];
    }

    /// euclidean length
    ///
    /// use lengthSquared if you only need to compare the length of two vectors.
    pub fn length(self: *const Vec3) f64 {
        return std.math.sqrt(self.lengthSquared());
    }
    /// squared length
    ///
    /// used to compare the length of two vectors without the cost of the sqrt
    /// call.
    pub fn lengthSquared(self: *const Vec3) f64 {
        return self.inner[0] * self.inner[0] + self.inner[1] * self.inner[1] + self.inner[2] * self.inner[2];
    }

    pub fn dot(self: *const Vec3, other: *const Vec3) f64 {
        return @reduce(.Add, self.inner * other.inner);
    }

    pub fn cross(self: *const Vec3, other: *const Vec3) Vec3 {
        return .{ .inner = .{
            self.inner[1] * other.inner[2] - self.inner[2] * other.inner[1],
            self.inner[2] * other.inner[0] - self.inner[0] * other.inner[2],
            self.inner[0] * other.inner[1] - self.inner[1] * other.inner[0],
        } };
    }

    pub fn unitVector(self: *const Vec3) Vec3 {
        const len = self.length();

        return .{ .inner = self.inner / Vec3.splat(len).inner };
    }

    pub fn write_color(out: *std.Io.Writer, color: *const Vec3) !void {
        const intensity: Interval = .new(0.000, 0.999);
        const ir: u32 = @intFromFloat(256 * intensity.clamp(color.r()));
        const ig: u32 = @intFromFloat(256 * intensity.clamp(color.g()));
        const ib: u32 = @intFromFloat(256 * intensity.clamp(color.b()));

        var row_buf: [128]u8 = undefined;
        const pix = try std.fmt.bufPrint(&row_buf, "{d} {d} {d}\n", .{ ir, ig, ib });
        _ = try out.write(pix);
    }
};

pub const Interval = struct {
    min: f64,
    max: f64,

    pub const empty: Interval = .{
        .max = -std.math.inf(f64),
        .min = std.math.inf(f64),
    };

    pub const universe: Interval = .{
        .max = std.math.inf(f64),
        .min = -std.math.inf(f64),
    };

    pub fn new(min: f64, max: f64) Interval {
        return .{
            .max = max,
            .min = min,
        };
    }

    pub fn interval(min: f64, max: f64) Interval {
        return new(min, max);
    }

    pub fn size(self: Interval) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, x: f64) bool {
        return self.min <= x and x <= self.max;
    }

    pub fn surrounds(self: Interval, x: f64) bool {
        return self.min < x and x < self.max;
    }

    pub fn clamp(self: Interval, x: f64) f64 {
        if (x < self.min) return self.min;
        if (x > self.max) return self.max;
        return x;
    }
};
