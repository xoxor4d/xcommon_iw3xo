#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0
#include <shader_vars.h>

struct V_IN
{
	float3 position : POSITION;
    float2 texcoord : TEXCOORD;
};

struct V_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD0;
	//float4 depth    : TEXCOORD1;
};

V_OUT vs_main( V_IN input ) 
{
	V_OUT output = (V_OUT)0;

    // ORG VS WORKING RESAMPLE
    // output.position = mul(float4(input.position.xyz, 1.0f), worldViewProjectionMatrix);
	// output.tc = input.tc;
	// ***************************************************


	output.position = mul(float4(input.position.xyz, 1.0f), worldViewProjectionMatrix);

	output.texcoord = input.texcoord;
	//output.depth    = output.position * clipSpaceLookupScale + output.position.w * clipSpaceLookupOffset; // works but close range
	// depth lenght with red channel in ps

	return output;
}
