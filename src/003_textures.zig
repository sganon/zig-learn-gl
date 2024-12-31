const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const fetch = sokol.fetch;
const shd = @import("shaders/003_textures_mix.glsl.zig");

const zigimg = @import("zigimg");

const math = @import("./math.zig");

const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var file_buffer: fetch.Range = .{};
    var img: sg.Image = .{};
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&[_]f32{
            // position      // colors          // texture
            0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, // top-right
            0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, // bottom-right
            -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, // bottom-left
            -0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, // top-left
        }),
    });

    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(&[_]u16{
            0, 1, 3,
            1, 2, 3,
        }),
    });
    var img_desc: sg.ImageDesc = .{
        .width = 512,
        .height = 512,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var image = zigimg.Image.fromFilePath(allocator, "src/assets/container.png") catch |err| {
        std.debug.print("err {}", .{err});
        return;
    };
    defer image.deinit();

    _ = image.convert(.rgba32) catch |err| {
        std.debug.print("err {}", .{err});
        return;
    };

    std.debug.print("first pixel: r:{}, g:{}, b:{}, a:{}\n\n", .{ image.pixels.rgba32[0].r, image.pixels.rgba32[0].g, image.pixels.rgba32[0].b, image.pixels.rgba32[0].a });

    img_desc.data.subimage[0][0] = sg.asRange(image.pixels.rgba32);
    img_desc.data.subimage[0][0].size = @intCast(512 * 512 * 4);
    std.debug.print("img_desc {}\n\n", .{img_desc.data.subimage[0][0]});
    state.bind.images[shd.IMG_tex] = sg.makeImage(img_desc);
    std.debug.print("bind images", .{});
    state.bind.samplers[shd.SMP_smp] = sg.makeSampler(.{});

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.triangleShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
    };
    pip_desc.layout.attrs[shd.ATTR_triangle_pos].format = .FLOAT3;
    pip_desc.layout.attrs[shd.ATTR_triangle_color0].format = .FLOAT4;
    pip_desc.layout.attrs[shd.ATTR_triangle_texcoord0].format = .FLOAT2;
    state.pip = sg.makePipeline(pip_desc);
    state.pass_action.colors[0] = .{ .load_action = .CLEAR };
}

export fn frame() void {
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
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
