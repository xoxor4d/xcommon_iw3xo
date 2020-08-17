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

// filtertap00 = xo_ssao_noisescale
// filtertap01 = xo_ssao_strength
// filtertap02 = xo_ssao_base
// filtertap03 = xo_ssao_area

// filtertap10 = xo_ssao_radius
// filtertap11 = xo_ssao_blur
// filtertap12 = current FOV / FOVSCALE
// filtertap13 = xo_ssao_numDir

// filtertap20 = xo_ssao_contrast
// filtertap21 = xo_ssao_attenuation
// filtertap22 = xo_ssao_angleBias
// filtertap23 = xo_ssao_numSteps

float normpdf(in float x, in float sigma)
{
	return 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

PixelOutput ps_main( const PixelInput pixel )
{
    // define our output struct as "fragment"
    PixelOutput fragment;

    /* //float2 texelSize = float2(texelSizeX, texelSizeY);
    float2 texelSize = float2(1.0f / (1.0f * filterTap[0][2]), 1.0f / (1.0f * filterTap[0][3]));
    float result = 0.0;

    for (int x = -2; x < 2; ++x) 
    {
        for (int y = -2; y < 2; ++y) 
        {
            float2 offset = float2(float(x), float(y)) * texelSize;
            result += tex2D(colorMapSampler, pixel.texcoord + offset).r;
        }
    }

    result /= 4.0 * 4.0;
    fragment.color = float4(result, result, result, 1.0f);

 */


    //
    // blur

    float2 perspective_texcoords = pixel.texcoord;
    float3 c = tex2D( colorMapSampler, perspective_texcoords ).rgb;

	//declare stuff
	const int mSize = 11;
	const int kSize = (mSize - 1 ) / 2;
	float kernel[mSize];
	float3 final_colour = float3(0.0, 0.0, 0.0);
	
	//create the 1-D kernel
	float sigma = 16.0;
	float Z = 0.0;

	for (int j = 0; j <= kSize; ++j)
	{
		kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
	}
	
	//get the normalization factor (as the gaussian has been clamped)
	for (int j = 0; j < mSize; ++j)
	{
		Z += kernel[j];
	}
	
	//read out the texels
	for (int i=-kSize; i <= kSize; ++i)
	{
		for (int j=-kSize; j <= kSize; ++j)
		{
			final_colour += kernel[kSize+j] * kernel[kSize+i] * tex2D(colorMapSampler, perspective_texcoords + float2(float(i), float(j)) / renderTargetSize.xy).rgb;
		}
	}
		
	fragment.color = float4(final_colour/(Z*Z), 1.0);

    // ----------



	return fragment;
}