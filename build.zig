const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exercises = .{
        "000_hello_triangle",
        "001_shaders",
        "002_attributes",
        "003_textures",
        "004_textures_mix",
        "005_transform",
        "006_coordinates",
        "007_cube",
        "008_camera",
        "009_camera_movement",
    };

    inline for (exercises) |exercise| {
        try buildExercise(b, exercise, .{ .target = target, .optimize = optimize });
    }
}

const ExerciseOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

fn buildExercise(b: *std.Build, comptime name: []const u8, options: ExerciseOptions) !void {
    const main_src = "src/" ++ name ++ ".zig";
    var run: ?*std.Build.Step.Run = null;
    const exercise = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(main_src),
        .target = options.target,
        .optimize = options.optimize,
    });

    const dep_sokol = b.dependency("sokol", .{
        .target = options.target,
        .optimize = options.optimize,
    });
    const dep_zigimg = b.dependency("zigimg", .{
        .target = options.target,
        .optimize = options.optimize,
    });

    exercise.root_module.addImport("sokol", dep_sokol.module("sokol"));
    exercise.root_module.addImport("zigimg", dep_zigimg.module("zigimg"));
    b.installArtifact(exercise);
    run = b.addRunArtifact(exercise);
    b.step("run-" ++ name, "Run " ++ name).dependOn(&run.?.step);

    buildShader(b, name, options.target);
}

fn buildShader(b: *std.Build, comptime name: []const u8, target: std.Build.ResolvedTarget) void {
    const shaders_dir = "src/shaders/";
    const shdc_step = b.step("shaders-" ++ name, "Compile shaders (needs ../sokol-tools-bin)");
    const glsl = if (target.result.isDarwin()) "glsl410" else "glsl430";
    const slang = glsl ++ ":metal_macos:hlsl5:glsl300es:wgsl";
    const cmd = b.addSystemCommand(&.{
        "sokol-shdc",
        "-i",
        shaders_dir ++ name ++ ".glsl",
        "-o",
        shaders_dir ++ name ++ ".glsl" ++ ".zig",
        "-l",
        slang,
        "-f",
        "sokol_zig",
        "--reflection",
    });
    shdc_step.dependOn(&cmd.step);
}
