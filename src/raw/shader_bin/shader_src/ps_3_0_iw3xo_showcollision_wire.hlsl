#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1
#include <shader_vars.h>

struct PixelInput
{
	float4 position 	: POSITION;
	float4 color 		: COLOR;
};

struct PixelOutput
{
	float4 color : COLOR;
};

PixelOutput ps_main( const PixelInput pixel )
{
    PixelOutput fragment;

	fragment.color = pixel.color;

	return fragment;
}
