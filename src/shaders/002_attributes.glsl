/* triangle vertex shader */
@vs vs

in vec4 position;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = position;
    color = color0;
}
@end

/* triangle fragment shader */
@fs fs

in vec4 color;

out vec4 frag_color;

layout(binding=0) uniform fs_params {
  vec4 ourColor;
};

void main() {
    frag_color = (color + ourColor) / 2;
}
@end

/* triangle shader program */
@program triangle vs fs

