# Zig Learn GL

Implementation examples of [learnopengl.com](https://learnopengl.com/) using [sokol](https://github.com/floooh/sokol) and its zig-bindings [sokol-zig](https://github.com/floooh/sokol-zig)

## Description

This is just a learning project to learn zig and openGL. The examples goes to the end of the first chapter [Camera](https://learnopengl.com/Getting-started/Camera).

## Build

Each exercices has its own shaders written in GLSL (located in `src/shaders`) and its own indepent zig program located in `src/`

To build and run the program you first need to compile the shaders using [sokol-shdc](https://github.com/floooh/sokol-tools-bin) . 

For convenience everything can be run via `zig build` for example to run the first `src/000_hello_triangle.zig` program you can run:

```shell
zig build shaders-000_hello_triangle && zig build run-000_hello_triangle


