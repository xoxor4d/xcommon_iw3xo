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

static float FOV = 1.0f * filterTap[1][2]; // 1.0 * cg_fov / cg_fovScale
//static float2 rcpres = float2(texelSizeX, texelSizeY); // size of 1 pixel horz. and vert.
static float2 rcpres = float2(1.0f / (1.0f * filterTap[0][2]), 1.0f / (1.0f * filterTap[0][3]));
static float2 realRenderTargetSize = float2(1.0f * filterTap[0][2], 1.0f * filterTap[0][3]);

//static const float2 g_InvFocalLen = { tan(0.5f * radians(FOV)) / rcpres.y * rcpres.x, tan(0.5f * radians(FOV)) }; 
static const float2 g_InvFocalLen = { tan(1.0f * radians(FOV)) / rcpres.y * rcpres.x, tan(0.5f * radians(FOV)) }; 

static const float2 g_FocalLen = 1.0 / g_InvFocalLen;
static float _ANGLEBIAS = (1.0f * filterTap[2][2]) * (M_PI / 180); // xo_ssao_attenuation // stock = 30 * (M_PI / 180) == 0.523; // maybe create a dvar

float2 rotate_direction(float2 Dir, float2 CosSin)
{
    return float2(Dir.x*CosSin.x - Dir.y*CosSin.y, 
                  Dir.x*CosSin.y + Dir.y*CosSin.x);
}

//----------------------------------------------------------------------------------
float3 uv_to_eye(float2 uv, float eye_z)
{
    uv = (uv * float2(2.0, -2.0) - float2(1.0, -1.0));
    return float3(uv * g_InvFocalLen * eye_z, eye_z);
}

//----------------------------------------------------------------------------------
float3 fetch_eye_pos(float2 uv)
{
    float z = tex2D(floatZSampler, uv).r;
    return uv_to_eye(uv, z);
}

//----------------------------------------------------------------------------------
float length2(float3 v) { return dot(v, v); } 

//----------------------------------------------------------------------------------
float2 snap_uv_offset(float2 uv)
{
    //return round(uv * renderTargetSize) * rcpres;
    return round(uv * realRenderTargetSize) * rcpres;
}

//----------------------------------------------------------------------------------
float3 min_diff(float3 P, float3 Pr, float3 Pl)
{
    float3 V1 = Pr - P;
    float3 V2 = P - Pl;
    return (length2(V1) < length2(V2)) ? V1 : V2;
}

//----------------------------------------------------------------------------------
float tangent(float3 P, float3 S)
{
    return (P.z - S.z) / length(S.xy - P.xy);
}

//----------------------------------------------------------------------------------
float tan_to_sin(float x)
{
    return x * rsqrt(x*x + 1.0f);
}

//----------------------------------------------------------------------------------
float falloff(float r)
{
    const float _ATTENUATION = 1.0f * filterTap[2][1]; // xo_ssao_attenuation
    return 1.0f - _ATTENUATION * r * r; 
}

//----------------------------------------------------------------------------------
float invlength(float2 v)
{
    return rsqrt(dot(v,v));
}

//----------------------------------------------------------------------------------
float tangent(float3 T)
{
    return -T.z * invlength(T.xy);
}

//----------------------------------------------------------------------------------
float biased_tangent(float3 T)
{
    float phi = atan(tangent(T)) + _ANGLEBIAS;
    return tan(min(phi, M_PI * 0.5));
}

//----------------------------------------------------------------------------------
void integrate_direction(inout float ao, float3 P, float2 uv, float2 deltaUV, float tanH, float sinH, float radius, float numSteps)
{
    // our shader compiler doesnt like branching with varying vars, so we need to hard code it ..

    for (float j = 1; j <= 8; ++j) 
    {
        uv += deltaUV;
        float3 S = fetch_eye_pos(uv);
        
        // Ignore any samples outside the radius of influence
        float d2  = length2(S - P);
        float g_inv_R = 1.0 / radius;
        float g_sqr_R = radius * radius;

        if (d2 < g_sqr_R) // g_sqr_R = radius * radius
        {
            float tanS = tangent(P, S);

            if(tanS > tanH) 
            {
                // Accumulate AO between the horizon and the sample
                float sinS = tanS / sqrt(1.0f + tanS*tanS);
                float r = sqrt(d2) * g_inv_R;
                ao += falloff(r) * (sinS - sinH);
                
                // Update the current horizon angle
                tanH = tanS;
                sinH = sinS;
            }
        }
    }
}

//----------------------------------------------------------------------------------
float AccumulatedHorizonOcclusion_LowQuality(float2 deltaUV, float2 uv0, float3 P, float randstep, float radius, float numSteps)
{
    // Randomize starting point within the first sample distance
    float2 uv = uv0 + snap_uv_offset( randstep * deltaUV );
    
    // Snap increments to pixels to avoid disparities between xy 
    // and z sample locations and sample along a line
    deltaUV = snap_uv_offset( deltaUV );

    // Add an epsilon in case _ANGLEBIAS==0.0f
    float tanT = tan(-M_PI * 0.5 + _ANGLEBIAS + 1.e-5f); // _ANGLEBIAS == m_AngleBias(30) * (M_PI / 180)
    float sinT = (_ANGLEBIAS != 0.0) ? tan_to_sin(tanT) : -1.0;

    float ao = 0;
    integrate_direction(ao, P, uv, deltaUV, tanT, sinT, radius, numSteps);

    // Integrate opposite directions together
    deltaUV = -deltaUV;
    uv = uv0 + snap_uv_offset( randstep * deltaUV );
    integrate_direction(ao, P, uv, deltaUV, tanT, sinT, radius, numSteps);

    // Divide by 2 because we have integrated 2 directions together
    // Subtract 1 and clamp to remove the part below the surface
    return max(ao * 0.5 - 1.0, 0.0);
}

//----------------------------------------------------------------------------------
float AccumulatedHorizonOcclusion(float2 deltaUV, float2 uv0, float3 P, float randstep, float3 dPdu, float3 dPdv, float radius )
{
    // Randomize starting point within the first sample distance
    float2 uv = uv0 + snap_uv_offset( randstep * deltaUV );

    float g_inv_R = 1.0 / radius;
    float g_sqr_R = radius * radius;
    
    // Snap increments to pixels to avoid disparities between xy 
    // and z sample locations and sample along a line
    deltaUV = snap_uv_offset( deltaUV );

    // Compute tangent vector using the tangent plane
    float3 T = deltaUV.x * dPdu + deltaUV.y * dPdv;

    float tanH = biased_tangent(T);
    float sinH = tanH / sqrt(1.0f + tanH * tanH);

    float ao = 0;
    for(float j = 1; j <= 8.0; ++j) 
    {
        uv += deltaUV;
        float3 S = fetch_eye_pos(uv);
        
        // Ignore any samples outside the radius of influence
        float d2  = length2(S - P);
        if (d2 < g_sqr_R) 
        {
            float tanS = tangent(P, S);

            if(tanS > tanH) 
            {
                // Accumulate AO between the horizon and the sample
                float sinS = tanS / sqrt(1.0f + tanS * tanS);
                float r = sqrt(d2) * g_inv_R;
                ao += falloff(r) * (sinS - sinH);
                
                // Update the current horizon angle
                tanH = tanS;
                sinH = sinS;
            }
        } 
    }

    return ao;
}

//----------------------------------------------------------------------------------
PixelOutput ps_main( const PixelInput pixel )
{
    // define our output struct as "fragment"
    PixelOutput fragment;

    float _NOISESCALE     = 1.0f      * filterTap[0][0]; // xo_ssao_noisescale // 40.0
    float _STRENGTH       = 1.0f      * filterTap[0][1]; // xo_ssao_strenght   // 2.0
    float _BASE           = 1.0f      * filterTap[0][2]; // xo_ssao_base       // 1.4
    float _AREA           = 1.0f      * filterTap[0][3]; // xo_ssao_area       // 100.0
    const float _FALLOFF        = 0.000001f;                        
    float _RADIUS         = 1.0f      * filterTap[1][0]; // xo_ssao_radius    // 0.06

    const float _NUMSTEPS       = 8.0f; // xo_ssao_numSteps  // 8.0  // not in use, not avail. on PS3.0
    const float _NUMDIR         = 16.0f; // xo_ssao_numDir    // 16.0 // not in use, not avail. on PS3.0
    float _CONTRAST       = 1.0f      * filterTap[2][0]; // xo_ssao_contrast  // 1.25

    const float _NUMSTEPS_STATIC    = 8.0f;
    const float _NUMDIR_STATIC      = 10.0f;

    float3 P = fetch_eye_pos(pixel.texcoord);

    // Project the radius of influence _RADIUS from eye space to texture space.
    // The scaling by 0.5 is to go from [-1,1] to [0,1].
    float2 step_size = 0.5 * _RADIUS * g_FocalLen / P.z; // _RADIUS = R = m_RadiusMultiplier * m_AORadius;

    // Early out if the projected radius is smaller than 1 pixel.
    //float numSteps = min ( _NUMSTEPS_STATIC, min(step_size.x * renderTargetSize.x, step_size.y * renderTargetSize.y));
    float numSteps = min ( _NUMSTEPS_STATIC, min(step_size.x * realRenderTargetSize.x, step_size.y * realRenderTargetSize.y));
    
    if( numSteps < 1.0 ) 
    {
        fragment.color = float4( 1.0, 1.0, 1.0, 1.0 );
	    //return fragment; // broken, use else
    }

    else
    {
        step_size = step_size / ( numSteps + 1 );

        // Nearest neighbor pixels on the tangent plane
        float3 Pr, Pl, Pt, Pb;
        float4 tangentPlane;

        Pr = fetch_eye_pos(pixel.texcoord + float2(rcpres.x, 0));
        Pl = fetch_eye_pos(pixel.texcoord + float2(-rcpres.x, 0));
        Pt = fetch_eye_pos(pixel.texcoord + float2(0, rcpres.y));
        Pb = fetch_eye_pos(pixel.texcoord + float2(0, -rcpres.y));

        float3 N = normalize(cross(Pr - Pl, Pt - Pb));
        tangentPlane = float4(N, dot(P, N));

        // Screen-aligned basis for the tangent plane
        //float3 dPdu = min_diff(P, Pr, Pl);
        //float3 dPdv = min_diff(P, Pt, Pb) * (renderTargetSize.y * rcpres.x);

        // (cos(alpha),sin(alpha),jitter)
        //float3 rand = tRandom.Load(int3((int)IN.pos.x&63, (int)IN.pos.y&63, 0)).xyz;
        //float3 rand = normalize( tex2D(colorMapSampler1, renderTargetSize.xy * pixel.texcoord.xy / _NOISESCALE ).rgb * 2.0f - 1.0f);

        /* float ao = 0;
        float d;
        float alpha = 2.0f * M_PI / _NUMDIR_STATIC;

        for (d = 0; d < _NUMDIR_STATIC; ++d) 
        {
                float angle = alpha * d;
                float2 dir = float2(cos(angle), sin(angle));
                float2 deltaUV = rotate_direction(dir, rand.xy) * step_size.xy;

                // LOW QUALITY
                if(filterTap[0][1] == 0.0f) {
                    ao += AccumulatedHorizonOcclusion_LowQuality(deltaUV, pixel.texcoord, P, rand.z, _RADIUS, numSteps);
                }
                
                // HBAO
                else if(filterTap[0][1] == 1.0f) {
                    ao += AccumulatedHorizonOcclusion(deltaUV, pixel.texcoord, P, rand.z, dPdu, dPdv, _RADIUS);
                }
                
                else {
                    ao += 0.125f;
                }
        }

        ao *= 2.0;

        float finalAO =  1.0 - ao / _NUMDIR_STATIC * _CONTRAST; */

        fragment.color = float4(tangentPlane.rgb, 1.0f );
    }

	return fragment;
}