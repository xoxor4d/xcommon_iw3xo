// * COD4-SHADERGEN - xoxor4d.github.io
// * Template used : [vs_3_0_shadergen_2d_no_image.hlsl]
// * Mat. Template : [shadergen_2d_no_image.template]

#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0

#include <shader_vars.h>
#include <lib/vertex_setup_dtex.hlsl>

// input struct
struct VS_IN
{
    float4 position : POSITION;
    float4 texcoord : TEXCOORD;
};

// output struct
struct VS_OUT
{
    float4 position : POSITION;
    float2 texcoord : TEXCOORD;
};

VS_OUT vs_main(VS_IN i)
{
    VS_OUT o;

    // transform vertices to clip
    o.position = mul(float4(i.position.xyz, 1.0f), worldViewProjectionMatrix);
   
    o.texcoord = setup_uv_dtex(i.texcoord);

	return o;
}
