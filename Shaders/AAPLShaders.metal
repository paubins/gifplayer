/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#include "../AAPLShaderTypes.h"

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls
typedef enum TextureIndices {
    kTextureIndexColor    = 0,
    kTextureIndexY        = 1,
    kTextureIndexCbCr     = 2
} TextureIndices;

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
} ImageColorInOut;


struct RasterizerData
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;

};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]])

{

    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
//    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
//
//    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
//    //   interpolated with the other textureCoordinate values in the vertices that make up the
//    //   triangle.
//    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    
//    float2 inverseViewSize(1.0f / viewportSize.x, ); // passed in a buffer
    float2 inverseViewSize = 1 / viewportSize;
//    float clipX = (2.0f * vertexArray[vertexID].position.x * (1.0f / inverseViewSize.x)) - 1.0f;
//    float clipY = (2.0f * -vertexArray[vertexID].position.y * (1.0f / inverseViewSize.y)) + 1.0f;
    float clipX = (2.0f * vertexArray[vertexID].position.x * inverseViewSize.x) - 1.0f;
    float clipY = (2.0f * -vertexArray[vertexID].position.y * inverseViewSize.y) + 1.0f;
    
    float4 clipPosition(clipX, clipY, 0.0f, 1.0f);
    
    out.position.xy = pixelSpacePosition;  // / (viewportSize / 2.0);

    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4
samplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    // return the color of the texture
    return float4(colorSample);
}

fragment float4 capturedImageFragmentShader(RasterizerData in [[stage_in]],
                                            texture2d<float, access::sample> capturedImageTextureY [[ texture(kTextureIndexY) ]],
                                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(kTextureIndexCbCr) ]]) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate.
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.textureCoordinate).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.textureCoordinate).rg, 1.0);
    
    // Return the converted RGB color.
    return ycbcrToRGBTransform * ycbcr;
}
