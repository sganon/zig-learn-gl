const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const fetch = sokol.fetch;
const shd = @import("shaders/007_cube.glsl.zig");

const zigimg = @import("zigimg");

const math = @import("./math.zig");

const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var file_buffer: fetch.Range = .{};
    var img: sg.Image = .{};
};

fn loadAndBindImage(allocator: std.mem.Allocator, path: []const u8, imageIndex: u32) void {
    var img_desc: sg.ImageDesc = .{
        .width = 512,
        .height = 512,
    };

    var image = zigimg.Image.fromFilePath(allocator, path) catch |err| {
        std.debug.print("err {}\n", .{err});
        return;
    };
    defer image.deinit();

    _ = image.convert(.rgba32) catch |err| {
        std.debug.print("err {}\n", .{err});
        return;
    };

    img_desc.data.subimage[0][0] = sg.asRange(image.pixels.rgba32);
    img_desc.data.subimage[0][0].size = @intCast(512 * 512 * 4);
    std.debug.print("img_desc {}\n\n", .{img_desc.data.subimage[0][0]});
    state.bind.images[imageIndex] = sg.makeImage(img_desc);
}

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sokol.time.setup();

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{ -0.5, -0.5, -0.5, 0.0, 0.0, 0.5, -0.5, -0.5, 1.0, 0.0, 0.5, 0.5, -0.5, 1.0, 1.0, 0.5, 0.5, -0.5, 1.0, 1.0, -0.5, 0.5, -0.5, 0.0, 1.0, -0.5, -0.5, -0.5, 0.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, 0.5, -0.5, 0.5, 1.0, 0.0, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 1.0, -0.5, 0.5, 0.5, 0.0, 1.0, -0.5, -0.5, 0.5, 0.0, 0.0, -0.5, 0.5, 0.5, 1.0, 0.0, -0.5, 0.5, -0.5, 1.0, 1.0, -0.5, -0.5, -0.5, 0.0, 1.0, -0.5, -0.5, -0.5, 0.0, 1.0, -0.5, -0.5, 0.5, 0.0, 0.0, -0.5, 0.5, 0.5, 1.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.5, 0.5, -0.5, 1.0, 1.0, 0.5, -0.5, -0.5, 0.0, 1.0, 0.5, -0.5, -0.5, 0.0, 1.0, 0.5, -0.5, 0.5, 0.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, -0.5, -0.5, -0.5, 0.0, 1.0, 0.5, -0.5, -0.5, 1.0, 1.0, 0.5, -0.5, 0.5, 1.0, 0.0, 0.5, -0.5, 0.5, 1.0, 0.0, -0.5, -0.5, 0.5, 0.0, 0.0, -0.5, -0.5, -0.5, 0.0, 1.0, -0.5, 0.5, -0.5, 0.0, 1.0, 0.5, 0.5, -0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 0.0, 0.5, 0.5, 0.5, 1.0, 0.0, -0.5, 0.5, 0.5, 0.0, 0.0, -0.5, 0.5, -0.5, 0.0, 1.0 }),
    });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    loadAndBindImage(allocator, "src/assets/container.png", shd.IMG_tex0);
    loadAndBindImage(allocator, "src/assets/awesomeface.png", shd.IMG_tex1);

    state.bind.samplers[shd.SMP_smp] = sg.makeSampler(.{});

    var pip_desc: sg.PipelineDesc = .{ .shader = sg.makeShader(shd.triangleShaderDesc(sg.queryBackend())), .depth = .{
        .compare = .LESS_EQUAL,
        .write_enabled = true,
    } };
    pip_desc.layout.attrs[shd.ATTR_triangle_pos].format = .FLOAT3;
    pip_desc.layout.attrs[shd.ATTR_triangle_texcoord0].format = .FLOAT2;
    state.pip = sg.makePipeline(pip_desc);
    state.pass_action.colors[0] = .{ .load_action = .CLEAR };
}

export fn frame() void {
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);

    const cubePositions = [_]math.Vec3{
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .{ .x = 2.0, .y = 5.0, .z = -15.0 },
        .{ .x = -1.5, .y = -2.2, .z = -2.5 },
        .{ .x = -3.8, .y = -2.0, .z = -12.3 },
        .{ .x = 2.4, .y = -0.4, .z = -3.5 },
        .{ .x = -1.7, .y = 3.0, .z = -7.5 },
        .{ .x = 1.3, .y = -2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 2.0, .z = -2.5 },
        .{ .x = 1.5, .y = 0.2, .z = -1.5 },
        .{ .x = -1.3, .y = 1.0, .z = -1.5 },
    };

    for (cubePositions) |pos| {
        var time: f32 = @floatFromInt(sokol.time.stm_now());
        time = time * 0.0000001; // Scale down the time for slower transition
        const position = math.Mat4.translate(pos);
        const rotate = math.Mat4.rotate(time, math.Vec3{ .x = 0.5, .y = 1.0, .z = 0.0 });
        const model = math.Mat4.mul(position, rotate);
        const view = math.Mat4.translate(math.Vec3{ .x = 0.0, .y = 0.0, .z = -3.0 });
        const projection = math.Mat4.persp(45.0, 640.0 / 480.0, 0.1, 100.0);

        sg.applyUniforms(shd.UB_fs_params, sg.asRange(&shd.FsParams{ .model = model.toArray(), .view = view.toArray(), .projection = projection.toArray() }));

        sg.draw(0, 36, 1);
    }

    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "000 Hello Triangle",
        .logger = .{ .func = slog.func },
    });
}
