#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input the mix value
// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer FloatArray {
    float data[];
}
inputBuffer;

// Separate buffers for image data
layout (set = 0, binding = 1, r8) restrict uniform readonly image2D noiseImage;
layout (set = 0, binding = 2, rgba8) restrict uniform readonly image2D baseImage;
layout (set = 0, binding = 3, rgba8) restrict uniform writeonly image2D outputImage;

// The code we want to execute in each invocation
void main() {
    float mixValue = inputBuffer.data[0];

    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    vec4 noiseColor = vec4(vec3(imageLoad(noiseImage, pos).r), 1.0);
    vec4 baseColor = imageLoad(baseImage, pos);

    vec4 newColor = mix(noiseColor, baseColor, mixValue);

    // Alpha should be 1.0 anyway, but can't be too careful
    newColor.a = 1.0;
    imageStore(outputImage, pos, newColor);
}