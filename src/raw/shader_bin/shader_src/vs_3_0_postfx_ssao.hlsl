#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0
#include <shader_vars.h>

struct VertexInput
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD0;
};

struct PixelInput
{
    float4 position     : POSITION;
    float2 texcoord     : TEXCOORD0;
	float2 tilecoords 	: TEXCOORD1;
};

float4 Transform_ClipSpacePosToTexCoords( float4 position )
{
	return position * clipSpaceLookupScale + position.w * clipSpaceLookupOffset;
}

PixelInput vs_main( const VertexInput vertex ) 
{
	PixelInput pixel;

	pixel.position = mul(float4(vertex.position.xyz, 1.0f), worldViewProjectionMatrix);
	pixel.texcoord = vertex.texcoord;
	pixel.tilecoords = vertex.position.xy / renderTargetSize.y * float2(0.01f, 0.01f);

	//pixel.screenCoords = Transform_ClipSpacePosToTexCoords( pixel.position );

	return pixel;
}