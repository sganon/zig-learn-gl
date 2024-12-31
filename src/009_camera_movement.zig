const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const fetch = sokol.fetch;
const time = sokol.time;
const shd = @import("shaders/009_camera_movement.glsl.zig");

const zigimg = @import("zigimg");

const math = @import("./math.zig");

const Camera = struct {
    position: math.Vec3,
    front: math.Vec3,
    up: math.Vec3,
};

const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
    var file_buffer: fetch.Range = .{};
    var img: sg.Image = .{};
    var last_time: u64 = 0;
    var delta_time: u64 = 0;
    var camera: Camera = .{
        .position = .{ .x = 0.0, .y = 0.0, .z = 10.0 },
        .front = .{ .x = 0.0, .y = 0.0, .z = -1.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    };
    var mouse_btn = false;
    var first_mouse = true;
    var last_x: f32 = 0.0;
    var last_y: f32 = 0.0;
    var yaw: f32 = 90.0;
    var pitch: f32 = 0.0;
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

    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shd.triangleShaderDesc(sg.queryBackend())),
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
    };
    pip_desc.layout.attrs[shd.ATTR_triangle_pos].format = .FLOAT3;
    pip_desc.layout.attrs[shd.ATTR_triangle_texcoord0].format = .FLOAT2;
    state.pip = sg.makePipeline(pip_desc);
    state.pass_action.colors[0] = .{ .load_action = .CLEAR };
}

export fn frame() void {
    state.delta_time = time.laptime(&state.last_time);

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

    for (0.., cubePositions) |i, pos| {
        const position = math.Mat4.translate(pos);
        const rotate = math.Mat4.rotate(20.0 * @as(f32, @floatFromInt(i)), math.Vec3{ .x = 0.5, .y = 1.0, .z = 0.0 });
        const model = math.Mat4.mul(position, rotate);

        const view = math.Mat4.lookat(state.camera.position, math.Vec3.add(state.camera.front, state.camera.position), state.camera.up);

        const projection = math.Mat4.persp(45.0, 640.0 / 480.0, 0.1, 100.0);

        sg.applyUniforms(shd.UB_fs_params, sg.asRange(&shd.FsParams{ .model = model.toArray(), .view = view.toArray(), .projection = projection.toArray() }));

        sg.draw(0, 36, 1);
    }

    sg.endPass();
    sg.commit();
}

export fn input(event: ?*const sapp.Event) void {
    const camera_speed: f32 = 2.5 * @as(f32, @floatCast(time.stm_sec(state.delta_time)));

    const ev = event.?;
    if (ev.type == .MOUSE_DOWN) {
        state.mouse_btn = true;
    }
    if (ev.type == .MOUSE_UP) {
        state.mouse_btn = false;
        state.first_mouse = true;
    }
    if (ev.type == .KEY_DOWN) {
        switch (ev.key_code) {
            .W => {
                state.camera.position = math.Vec3.add(state.camera.position, math.Vec3.scale(state.camera.front, camera_speed));
            },
            .S => {
                state.camera.position = math.Vec3.sub(state.camera.position, math.Vec3.scale(state.camera.front, camera_speed));
            },
            .A => {
                state.camera.position = math.Vec3.sub(state.camera.position, math.Vec3.mul(math.Vec3.norm(math.Vec3.cross(state.camera.front, state.camera.up)), camera_speed));
            },
            .D => {
                state.camera.position = math.Vec3.add(state.camera.position, math.Vec3.mul(math.Vec3.norm(math.Vec3.cross(state.camera.front, state.camera.up)), camera_speed));
            },
            else => {},
        }
    }
    if (ev.type == .MOUSE_MOVE and state.mouse_btn) {
        if (state.first_mouse) {
            state.last_x = ev.mouse_x;
            state.last_y = ev.mouse_y;
            state.first_mouse = false;
        }
        var xoffset = ev.mouse_x - state.last_x;
        var yoffset = state.last_y - ev.mouse_y;
        state.last_x = ev.mouse_x;
        state.last_y = ev.mouse_y;

        const sensitivity: f32 = 0.1;
        xoffset *= sensitivity;
        yoffset *= sensitivity;
        std.debug.print("offset x={} y={}\n", .{ xoffset, yoffset });

        state.yaw += xoffset;
        state.pitch += yoffset;

        if (state.pitch > 89.0) {
            state.pitch = 89.0;
        } else if (state.pitch < -89.0) {
            state.pitch = -89.0;
        }

        const direction = math.Vec3{
            .x = std.math.cos(math.radians(state.yaw)) * std.math.cos(math.radians(state.pitch)),
            //.y = 0,
            //.z = -1.0,
            .y = std.math.sin(math.radians(state.pitch)),
            .z = -(std.math.sin(math.radians(state.yaw)) * std.math.cos(math.radians(state.pitch))),
        };
        std.debug.print("direction {}\n", .{math.Vec3.norm(direction)});
        state.camera.front = math.Vec3.norm(direction);
    }
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "000 Hello Triangle",
        .logger = .{ .func = slog.func },
    });
}
