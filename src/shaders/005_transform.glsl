/* triangle vertex shader */
#pragma sokol @vs vs

layout(binding=0) uniform fs_params {
  mat4 transform;
};

in vec4 pos;
in vec4 color0;
in vec2 texcoord0;

out vec4 color;
out vec2 uv;

void main() {
    gl_Position = transform * pos;
    color = color0;
    uv = texcoord0;
}
#pragma sokol @end

/* triangle fragment shader */
#pragma sokol @fs fs

layout(binding=0) uniform texture2D tex0;
layout(binding=1) uniform texture2D tex1;
layout(binding=0) uniform sampler smp;

in vec4 color;
in vec2 uv;

out vec4 frag_color;

void main() {
    frag_color = mix(texture(sampler2D(tex0, smp), uv), texture(sampler2D(tex1, smp), uv), 0.2);
}
#pragma sokol @end

/* triangle shader program */
#pragma sokol @program triangle vs fs

