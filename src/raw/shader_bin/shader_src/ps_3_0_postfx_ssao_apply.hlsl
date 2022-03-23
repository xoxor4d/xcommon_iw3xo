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

// filtertap00 = noisescale
// filtertap01 = total_strength
// filtertap02 = base
// filtertap03 = area

// filtertap10 = radius
// filtertap11 = samples
// filtertap12 =
// filtertap13 =

PixelOutput ps_main( const PixelInput pixel )
{
    // define our output struct as "fragment"
    PixelOutput fragment;

    //float3 ao = tex2D(colorMapSampler, pixel.texcoord).rgb; // floatZSampler
    //float3 framebuffer = tex2D(colorMapPostSunSampler, pixel.texcoord).rgb;

    //fragment.color = float4(framebuffer * ao, 1.0f);

    fragment.color = float4(tex2D(colorMapSampler, pixel.texcoord).rrr, 1.0f);
	//fragment.color.r *= sin(gameTime.w);
	return fragment;
}