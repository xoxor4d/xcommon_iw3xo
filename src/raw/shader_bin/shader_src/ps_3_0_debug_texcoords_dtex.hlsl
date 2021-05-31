// * COD4-SHADERGEN - xoxor4d.github.io
// * Template used : [ps_3_0_shadergen_2d_no_image.hlsl]
// * Mat. Template : [shadergen_2d_no_image.template]

#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1

#include <shader_vars.h>

struct PS_IN
{
    float3 color        : COLOR;
    float2 texcoord     : TEXCOORD;
};

float4 ps_main(PS_IN i) : COLOR
{
     // shader output
    float4  color;

	        color.x = clamp(i.texcoord.x, 0, 1);
            color.y = clamp(i.texcoord.y, 0, 1);
            color.z = clamp(1 - i.texcoord.x - i.texcoord.y, 0, 1);
            color.w = 1.0f;

	return  color;
}
