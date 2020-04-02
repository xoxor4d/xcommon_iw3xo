#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1
#include <shader_vars.h>

//##[CEL SHADING]
#define EdgeStrength 4.00                  //[0.00 to 4.00] Overall strength of the cel edge outline effect. Affects the overall density.  0.00: no outlines.
#define EdgeFilter 0.60                    //[0.10 to 2.00] Filters out fainter cel edges. Use it for balancing the cel edge density. EG: for faces, foliage, etc.
#define EdgeThickness 2.00                 //[0.50 to 4.00] Thickness of the cel edges. Increase for thicker outlining.  Note: when downsampling, raise this to keep the same thickness.
#define PaletteType 1                      //[1|2|3] The color palette to use. 1 is Game Original, 2 is Animated Shading, 3 is Water Painting (Default is 2: Animated Shading).
#define UseYuvLuma 1                       //[0 or 1] Uses YUV luma calculations, or base color luma calculations. Yuv luma can produce a better shaded look.
#define LumaConversion 1                   //[0 or 1] Uses BT.601, or BT.709, RGB<-YUV->RGB conversions. Some games prefer 601, but most prefer 709. BT.709 is typically recommended. 
#define ColorRounding 1                    //[0 or 1] Uses rounding methods on colors. This can emphasise shaded toon colors. Looks good in some games, and odd in others.

#define PIXEL_SIZE float2( 1/renderTargetSize.x, 1.0/renderTargetSize.y )

static const float3 lumCoeff = float3(0.2126729, 0.7151522, 0.0721750);

float AvgLuminance(float3 color)
{
    return sqrt(
    (color.x * color.x * lumCoeff.x) +
    (color.y * color.y * lumCoeff.y) +
    (color.z * color.z * lumCoeff.z));
}

float3 RGBtoYUV(float3 RGB)
{
    static const float3x3 m = {
    0.2126, 0.7152, 0.0722,
   -0.09991,-0.33609, 0.436,
    0.615, -0.55861, -0.05639 };

    return mul(m, RGB);
}

float3 YUVtoRGB(float3 YUV)
{
    static const float3x3 m = {
    1.000, 0.000, 1.28033,
    1.000,-0.21482,-0.38059,
    1.000, 2.12798, 0.000 };

    return mul(m, YUV);
}

float4 CelPass(float4 color, float2 uv0)
{   
    float3 yuv;
    float3 sum = color.rgb;

    const int NUM = 9;
    const float2 RoundingOffset = float2(0.25, 0.25);
    const float3 thresholds = float3(9.0, 8.0, 6.0);

    float lum[NUM];
    float3 col[NUM];
    float2 set[NUM] = {
    float2(-0.0078125, -0.0078125),
    float2(0.00, -0.0078125),
    float2(0.0078125, -0.0078125),
    float2(-0.0078125, 0.00),
    float2(0.00, 0.00),
    float2(0.0078125, 0.00),
    float2(-0.0078125, 0.0078125),
    float2(0.00, 0.0078125),
    float2(0.0078125, 0.0078125) };

    for (int i = 0; i < NUM; i++)
    {
        col[i] = tex2D(colorMapPostSunSampler, uv0 + set[i] * RoundingOffset).rgb;

        #if ColorRounding == 1
        col[i].r = round(col[i].r * thresholds.r) / thresholds.r;
        col[i].g = round(col[i].g * thresholds.g) / thresholds.g;
        col[i].b = round(col[i].b * thresholds.b) / thresholds.b;
        #endif

        lum[i] = AvgLuminance(col[i].xyz);
        yuv = RGBtoYUV(col[i]);

        #if UseYuvLuma == 0
        yuv.r = round(yuv.r * thresholds.r) / thresholds.r;
        #else
        yuv.r = saturate(round(yuv.r * lum[i]) / thresholds.r + lum[i]);
        #endif
        
        yuv = YUVtoRGB(yuv);
        sum += yuv;
    }

    float3 shadedColor = (sum / NUM);
    float2 pixel = float2( (1/renderTargetSize.x) * EdgeThickness, (1/renderTargetSize.y) * EdgeThickness);

    float edgeX = dot(tex2D(colorMapPostSunSampler, uv0 + pixel).rgb, lumCoeff);
    edgeX = dot(float4(tex2D(colorMapPostSunSampler, uv0 - pixel).rgb, edgeX), float4(lumCoeff, -1.0));

    float edgeY = dot(tex2D(colorMapPostSunSampler, uv0 + float2(pixel.x, -pixel.y)).rgb, lumCoeff);
    edgeY = dot(float4(tex2D(colorMapPostSunSampler, uv0 + float2(-pixel.x, pixel.y)).rgb, edgeY), float4(lumCoeff, -1.0));

    float edge = dot(float2(edgeX, edgeY), float2(edgeX, edgeY));

    #if PaletteType == 1
    color.rgb = lerp(color.rgb, color.rgb + pow(edge, EdgeFilter) * -EdgeStrength, EdgeStrength);
    #elif (PaletteType == 2)
    color.rgb = lerp(color.rgb + pow(edge, EdgeFilter) * -EdgeStrength, shadedColor, 0.25);
    #elif (PaletteType == 3)
    color.rgb = lerp(shadedColor + edge * -EdgeStrength, pow(edge, EdgeFilter) * -EdgeStrength + color.rgb, 0.5);
    #endif

    color.a = AvgLuminance(color.rgb);

    return saturate(color);
}

float4 ps_main( float2 uv : TEXCOORD0, float4 depth : TEXCOORD1, float distance : TEXCOORD2 ) : COLOR
{
    // WORKING SAMPLER 1:1
    //float4 color;
    //float uvx = ( (v1.x - 0.0 ) * 1.0 / 1.0 );
    //float uvy = ( (v1.y - 0.0 ) * 1.0 / 1.0 );
    //float2 uv = float2( uvx, uvy );
    //color = float4( tex2D( colorMapSampler, uv ).xyz , 1.0 );
	//return color;
    // ***************************************************************

	float4 color;
	float4 depth2;

	depth2 = tex2D( colorMapPostSunSampler, uv ); // only gun + viewhands // needs r_zfeather 1!!!!!!!! // stops working on fullbright ..

	//color = tex2Dproj( floatZSampler, depth ); // floatZSampler
	//color.xyz = mul( abs(color.x), 0.00050625 ); // smaller value = larger dist
	//color.w = 1.0;

	//

	//float3 mixColor = lerp( depth2.rgb, color.xyz, color.r );

	//float4 bloomcol = BloomPass( depth2, uv );

	float4 finalcolor = CelPass( depth2, uv );

	/*
	depth2.z = 1.0;
	if( depth2.x > 0.99 && depth2.y > 0.99 && depth2.z > 0.99 )
		depth2.w = 0.0;
	else // mask to red
	{
		depth2 = float4( 1.0, 0.0, 0.0, 1.0 );
	}
	*/

	/*
	depth2.z = 1.0;
	if( depth2.x > 0.99 && depth2.y > 0.99 && depth2.z > 0.99 )
		depth2.w = 0.0;
	else // mask to red
	{
		depth2.w = 0.5;
	}
	*/

	return finalcolor;
}