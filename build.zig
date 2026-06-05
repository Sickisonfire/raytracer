const std = @import("std");
const Io = std.Io;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "raytracing_in_a_weekend",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    const show_cmd = b.addSystemCommand(&.{"kitty"});
    show_cmd.addArgs(&.{ "+kitten", "icat", "./zig-out/out.ppm" });
    show_cmd.step.dependOn(&run_cmd.step);

    const clean_step = b.step("clean", "Clean");
    clean_step.makeFn = cleanStepFn;

    const debug_step = b.step("show", "Show the resulting ppm in the terminal");
    debug_step.dependOn(&show_cmd.step);
}

fn cleanStepFn(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
    const io = step.owner.graph.io;
    const dir = std.Io.Dir.cwd().openDir(io, "zig-out", .{}) catch unreachable;
    defer dir.close(io);
    dir.deleteFile(io, "out.ppm") catch {
        std.debug.print("nothing to clean\n", .{});
    };
}
