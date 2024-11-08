#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer InputIntArray {
    int data[];
}
inputIntBuffer;
layout(set = 0, binding = 1, std430) restrict buffer InputFloatArray {
    float data[];
}
inputFloatBuffer;
layout (set = 0, binding = 2, rgba8) restrict uniform readonly image2D inputImage;
layout (set = 0, binding = 3, rgba8) restrict uniform writeonly image2D outputImage;
layout(set = 0, binding = 4, std430) writeonly buffer OutputIntArray {
    int data[];
}
outputIntBuffer;
layout(set = 0, binding = 5, std430) writeonly buffer OutputFloatArray {
    float data[];
}
outputFloatBuffer;


void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    vec4 inputColor = imageLoad(inputImage, pos);

    vec4 outputColor = vec4(1.0 - inputColor.r, inputColor.g, inputColor.b, inputColor.a);

    outputFloatBuffer.data[0] = inputFloatBuffer.data[3];
    outputIntBuffer.data[1] = inputIntBuffer.data[2];

    imageStore(outputImage, pos, inputColor);
}