const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const shd = @import("shaders/001_shaders.glsl.zig");

const math = @import("./math.zig");

const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sokol.time.setup();

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{ .data = sg.asRange(&[_]f32{
        0.0,  0.5,  0.0,
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,

        0.5,  0.8,  0.0,
        0.5,  0.2,  0.0,
        0.9,  0.2,  0.0,
    }) });

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.triangleShaderDesc(sg.queryBackend())),
    };
    pip_desc.layout.attrs[shd.ATTR_triangle_position].format = .FLOAT3;
    state.pip = sg.makePipeline(pip_desc);
    state.pass_action.colors[0] = .{ .load_action = .CLEAR };
}

export fn frame() void {
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    var time: f64 = @floatFromInt(sokol.time.stm_now());
    time = time * 0.000000001; // Scale down the time for slower transition
    const green_value: f64 = (std.math.sin(time) / 2.0) + 0.5;
    sg.applyUniforms(shd.UB_fs_params, sg.asRange(&shd.FsParams{ .color = [4]f32{ 0.0, @floatCast(green_value), 0.0, 1.0 } }));

    sg.draw(0, 6, 1);
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
