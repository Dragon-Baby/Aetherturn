#ifndef AETHERTURN_GRADIENT_AMBIENT_INCLUDED
#define AETHERTURN_GRADIENT_AMBIENT_INCLUDED

void SampleGradientAmbient_float(
    float3 NormalWS,
    float3 SkyColor,
    float3 EquatorColor,
    float3 GroundColor,
    out float3 AmbientColor)
{
    NormalWS = normalize(NormalWS);

    float up = clamp(NormalWS.y, -1.0, 1.0);

    AmbientColor = up >= 0.0
        ? lerp(EquatorColor, SkyColor, up)
        : lerp(EquatorColor, GroundColor, -up);
}

void SampleGradientAmbient_half(
    half3 NormalWS,
    half3 SkyColor,
    half3 EquatorColor,
    half3 GroundColor,
    out half3 AmbientColor)
{
    NormalWS = normalize(NormalWS);

    half up = clamp(NormalWS.y, -1.0, 1.0);

    AmbientColor = up >= 0.0
        ? lerp(EquatorColor, SkyColor, up)
        : lerp(EquatorColor, GroundColor, -up);
}

#endif
