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

PixelOutput ps_main( const PixelInput pixel )
{
    // define our output struct as "fragment"
    PixelOutput fragment;

    //float4 depthBuffer = tex2D(floatZSampler, pixel.texcoord);

    //float4 depth = mul(abs(depthBuffer.x), float4(0.00390625, 0.0009765625, 0.000244140625, 1));
    //fragment.color = float4(depth.xyz, 1.0f);

    



    // .x = 1 / 256; .y = 1 / 1024; .z = 1 / 4096
    //float3 c0 = float3(0.00390625, 0.0009765625, 0.000244140625);
    float3 c0 = float3(0.000244140625, 0.0009765625, 0.000244140625);

    float depthBuffer = tex2D(floatZSampler, pixel.texcoord).r;

    float ndcDepth = (2.0 * depthBuffer - 0.1f - 256.0f) / (256.0f - 0.1f);
    ndcDepth = (ndcDepth * 0.5) + 0.5;
    float3 dCol = float3(ndcDepth,ndcDepth,ndcDepth); 


    
    float absOfDepth = abs(depthBuffer);
    float3 f3OfDepth = float3(absOfDepth, absOfDepth, absOfDepth);
    float3 preCol = mul(f3OfDepth, c0);
    
    
    fragment.color = float4(dCol, 1.0f);

	return fragment;
}