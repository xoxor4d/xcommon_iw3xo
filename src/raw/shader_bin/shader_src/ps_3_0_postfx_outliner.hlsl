#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1
#include <shader_vars.h>

struct PixelInput
{
    float4 position     : POSITION;
    float2 texcoord     : TEXCOORD0;
};

// output struct
struct PixelOutput
{
	float4 color        : COLOR;
};

/* float3 normal_from_depth(float depth, float2 texcoords) 
{
    const float2 offset1 = float2(0.0, 1.0) / renderTargetSize;
    const float2 offset2 = float2(1.0, 0.0) / renderTargetSize;

    float depth1 = tex2D(colorMapSampler, texcoords + offset1).r;
    depth1 = pow(depth1, 1.0 + filterTap[2][3]);
    
    float depth2 = tex2D(colorMapSampler, texcoords + offset2).r;
    depth2 = pow(depth2, 1.0 + filterTap[2][3]);
  
    float3 p1 = float3(offset1, depth1 - depth);
    float3 p2 = float3(offset2, depth2 - depth);
    
    float3 normal = cross(p1, p2);
    normal.z = -normal.z;
    
    return normalize(normal) * 0.5 + 0.5;
} */

// Edges are drawn between areas where the edgeDepth is greater than _DepthThreshold
// filterTap[0][0] || xo_outliner_scale 
// filterTap[0][1] || xo_outliner_depthDiffScale
// filterTap[0][2] || xo_outliner_depthThreshold

// https://roystan.net/articles/outline-shader.html

PixelOutput ps_main( const PixelInput pixel )
{
    // define our output struct as "fragment"
    PixelOutput fragment;

    const float _SCALE              = 1.0f  * filterTap[0][0]; //   1.0
    const float _DEPTHDIFFSCALE     = 1.0f  * filterTap[0][1]; // 100.0
    const float _DEPTHTHRESHOLD     = 1.0f  * filterTap[0][2]; //   1.5

    float halfScaleFloor = floor(_SCALE * 0.5);
    float halfScaleCeil  = ceil(_SCALE * 0.5);

    float2 bottomLeftUV     = pixel.texcoord - float2(texelSizeX, texelSizeY) * halfScaleFloor;
    float2 topRightUV       = pixel.texcoord + float2(texelSizeX, texelSizeY) * halfScaleCeil;  
    float2 bottomRightUV    = pixel.texcoord + float2(texelSizeX * halfScaleCeil, -texelSizeY * halfScaleFloor);
    float2 topLeftUV        = pixel.texcoord + float2(-texelSizeX * halfScaleFloor, texelSizeY * halfScaleCeil);

    /* float depth0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomLeftUV).r;
    float depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topRightUV).r;
    float depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomRightUV).r;
    float depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topLeftUV).r; */

    float depth0 = tex2D(colorMapSampler, bottomLeftUV).r;
    float depth1 = tex2D(colorMapSampler, topRightUV).r;
    float depth2 = tex2D(colorMapSampler, bottomRightUV).r;
    float depth3 = tex2D(colorMapSampler, topLeftUV).r;

    float depthFiniteDifference0 = depth1 - depth0;
    float depthFiniteDifference1 = depth3 - depth2;
	
    float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * _DEPTHDIFFSCALE;
    float depthThreshold = _DEPTHTHRESHOLD * depth0;
    edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

    // non inverted has white edges
    // invert edges
    edgeDepth = 1.0 - edgeDepth;

    fragment.color = float4(edgeDepth, edgeDepth, edgeDepth, 1.0f );

    // toon shader
    // filterTap[2][0] == float 0 1 toon enabled
    // filterTap[2][1] == shades

    if(filterTap[2][0] == 1.0)
    {
        float SHADES = 1.0 * filterTap[2][1];
        float4 toonSample = tex2D(colorMapPostSunSampler, pixel.texcoord);
        
        //Calculating the brightness of the fragment (Actually it is the average color but that works fine too)
        float brightness = (toonSample.r + toonSample.g + toonSample.g) / 3.0; 

        //Calculating the shade 
        float shade = floor(brightness * float(SHADES));

        //Calculating the brightness of the shade
        float brighnessOfShade = shade / float(SHADES);

        //Calculating the brightness difference
        float factor = brightness / brighnessOfShade;

        //Applying the brightness difference
        toonSample.rgb /= float3(factor, factor, factor);
        toonSample.a = 1.0f;

        fragment.color *= toonSample;
    }

    // else sample framebuffer, mix only with outlines, not using Multiply but Blend as materail prop.
    else
    {
        float4 frameBuffer = float4(tex2D(colorMapPostSunSampler, pixel.texcoord).rgb, 1.0f);
        fragment.color *= frameBuffer;
    }

	return fragment;
}