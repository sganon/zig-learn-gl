const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const shd = @import("shaders/000_hello_triangle.glsl.zig");

const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

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
}

export fn frame() void {
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
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
