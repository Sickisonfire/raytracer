const std = @import("std");

pub const Point3 = Vec3;
pub const Color = Vec3;
pub const Vec3 = struct {
    inner: [3]f64,

    pub const zero = Vec3{ .inner = .{ 0.0, 0.0, 0.0 } };

    pub fn new(x_: f64, y_: f64, z_: f64) Vec3 {
        return Vec3{ .inner = .{ x_, y_, z_ } };
    }

    pub fn add(self: *Vec3, other: Vec3) void {
        self.inner[0] += other.inner[0];
        self.inner[1] += other.inner[1];
        self.inner[2] += other.inner[2];
    }

    pub fn sub(self: *Vec3, other: Vec3) void {
        self.inner[0] -= other.inner[0];
        self.inner[1] -= other.inner[1];
        self.inner[2] -= other.inner[2];
    }

    pub fn multScalar(self: *Vec3, t: f64) void {
        self.inner[0] *= t;
        self.inner[1] *= t;
        self.inner[2] *= t;
    }

    pub fn divScalar(self: *Vec3, t: f64) void {
        self.inner[0] /= t;
        self.inner[1] /= t;
        self.inner[2] /= t;
    }

    pub fn x(self: Vec3) f64 {
        return self.inner[0];
    }
    pub fn y(self: Vec3) f64 {
        return self.inner[1];
    }
    pub fn z(self: Vec3) f64 {
        return self.inner[2];
    }

    /// euclidean length
    ///
    /// use lengthSquared if you only need to compare the length of two vectors.
    pub fn length(self: Vec3) f64 {
        return std.math.sqrt(self.lengthSquared());
    }
    /// squared length
    ///
    /// used to compare the length of two vectors without the cost of the sqrt
    /// call.
    pub fn lengthSquared(self: Vec3) f64 {
        return self.inner[0] * self.inner[0] + self.inner[1] * self.inner[1] + self.inner[2] * self.inner[2];
    }

    pub fn dot(self: *Vec3, other: *Vec3) f64 {
        return self.inner[0] * other.inner[0] + self.inner[1] * other.inner[1] + self.inner[2] * other.inner[2];
    }

    pub fn cross(self: *Vec3, other: *Vec3) Vec3 {
        return Vec3{ .inner = .{
            self.inner[1] * other.inner[2] - self.inner[2] * other.inner[1],
            self.inner[2] * other.inner[0] - self.inner[0] * other.inner[2],
            self.inner[0] * other.inner[1] - self.inner[1] * other.inner[0],
        } };
    }

    pub fn unitVector(self: Vec3) Vec3 {
        const len = self.length();

        return Vec3{ .inner = .{
            self.inner[0] / len,
            self.inner[1] / len,
            self.inner[2] / len,
        } };
    }

    pub fn write_color(out: *std.Io.Writer, color: *const Vec3) !void {
        const ir: u32 = @intFromFloat(255.999 * color.inner[0]);
        const ig: u32 = @intFromFloat(255.999 * color.inner[1]);
        const ib: u32 = @intFromFloat(255.999 * color.inner[2]);

        var row_buf: [128]u8 = undefined;
        const pix = try std.fmt.bufPrint(&row_buf, "{d} {d} {d}\n", .{ ir, ig, ib });
        _ = try out.write(pix);
    }
};
