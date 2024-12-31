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

void main() {
    frag_color = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
@end

/* triangle shader program */
@program triangle vs fs

