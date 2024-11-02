#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout (set = 0, binding = 1, rgba8) restrict uniform readonly image2D inputImage;
layout (set = 0, binding = 2, rgba8) restrict uniform writeonly image2D outputImage;

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    vec4 inputColor = imageLoad(inputImage, pos);


    imageStore(outputImage, pos, inputColor);
}