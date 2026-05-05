#ifndef AETHERTURN_VERTEX_LIGHTS_INCLUDED
#define AETHERTURN_VERTEX_LIGHTS_INCLUDED

#define AETHERTURN_VERTEX_LIGHT_MAX 8

int _AetherVertexLightCount;
float4 _AetherVertexLightPositionRadius[AETHERTURN_VERTEX_LIGHT_MAX];
float4 _AetherVertexLightColorIntensity[AETHERTURN_VERTEX_LIGHT_MAX];

float3 AetherEvaluateVertexLights(float3 positionWS, float3 normalWS)
{
    float3 normal = normalize(normalWS);
    float3 lightSum = 0.0;
    int lightCount = min(_AetherVertexLightCount, AETHERTURN_VERTEX_LIGHT_MAX);

    [unroll]
    for (int i = 0; i < AETHERTURN_VERTEX_LIGHT_MAX; i++)
    {
        if (i >= lightCount)
        {
            break;
        }

        float4 positionRadius = _AetherVertexLightPositionRadius[i];
        float4 colorIntensity = _AetherVertexLightColorIntensity[i];

        float3 toLight = positionRadius.xyz - positionWS;
        float distanceSqr = max(dot(toLight, toLight), 1e-4);
        float radius = max(positionRadius.w, 1e-4);
        float radiusSqr = radius * radius;
        float3 lightDir = toLight * rsqrt(distanceSqr);

        float rangeAttenuation = saturate(1.0 - distanceSqr / radiusSqr);
        rangeAttenuation *= rangeAttenuation;

        float distanceAttenuation = rcp(max(distanceSqr, 1.0));
        float attenuation = rangeAttenuation * distanceAttenuation;
        float ndotl = saturate(dot(normal, lightDir));

        lightSum += colorIntensity.rgb * colorIntensity.a * attenuation * ndotl;
    }

    return lightSum;
}

void SampleVertexLights_float(float3 PositionWS, float3 NormalWS, out float3 LightColor)
{
    LightColor = AetherEvaluateVertexLights(PositionWS, NormalWS);
}

void SampleVertexLights_half(half3 PositionWS, half3 NormalWS, out half3 LightColor)
{
    LightColor = (half3)AetherEvaluateVertexLights((float3)PositionWS, (float3)NormalWS);
}

#endif
