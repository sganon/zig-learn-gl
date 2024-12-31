/* triangle vertex shader */
@vs vs

in vec4 position;

void main() {
    gl_Position = position;
}
@end

/* triangle fragment shader */
@fs fs
out vec4 frag_color;

layout(binding=0) uniform fs_params {
  vec4 color;
};

void main() {
    frag_color = color;
}
@end

/* triangle shader program */
@program triangle vs fs

