Shader "Aetherturn/Skybox/Cubemap Blend"
{
    Properties
    {
        _Tint ("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        _PulseProgress ("Pulse Progress", Range(0, 1)) = 0
        [Toggle] _ReverseBlend ("Reverse Blend (2 to 1)", Float) = 0
        _PulseSoftness ("Pulse Softness", Range(0.001, 0.3)) = 0.08
        [HDR] _PulseEdgeColor ("Pulse Edge Color", Color) = (0.5, 0.9, 1.5, 1)
        _PulseEdgeIntensity ("Pulse Edge Intensity", Range(0, 8)) = 1.5
        _PulseEdgeWidth ("Pulse Edge Width", Range(0.001, 0.3)) = 0.03
        [NoScaleOffset] _TexA ("Cubemap A (HDR)", Cube) = "grey" {}
        [NoScaleOffset] _TexB ("Cubemap B (HDR)", Cube) = "grey" {}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "RenderType" = "Background"
            "PreviewType" = "Skybox"
            "RenderPipeline" = "UniversalPipeline"
        }

        Cull Off
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            samplerCUBE _TexA;
            samplerCUBE _TexB;
            half4 _TexA_HDR;
            half4 _TexB_HDR;
            half4 _Tint;
            half _Exposure;
            half _PulseProgress;
            half _PulseSoftness;
            half _ReverseBlend;
            half4 _PulseEdgeColor;
            half _PulseEdgeIntensity;
            half _PulseEdgeWidth;
            float _Rotation;

            float3 RotateAroundYInDegrees(float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina;
                float cosa;
                sincos(alpha, sina, cosa);
                float2x2 rotationMatrix = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(rotationMatrix, vertex.xz), vertex.y).xzy;
            }

            struct appdata_t
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 rotated = RotateAroundYInDegrees(v.vertex.xyz, _Rotation);
                o.vertex = UnityObjectToClipPos(rotated);
                o.texcoord = v.vertex.xyz;
                return o;
            }

            half GetPulseBlend(float3 direction)
            {
                half topDistance = 1.0h - saturate(direction.y * 0.5h + 0.5h);
                half progress = saturate(_PulseProgress);
                half softness = max(_PulseSoftness, 0.001h);
                half startGate = smoothstep(0.0h, softness, progress);
                half fillMask = 1.0h - smoothstep(progress, progress + softness, topDistance);
                return saturate(fillMask * startGate);
            }

            half GetPulseEdgeMask(float3 direction)
            {
                half topDistance = 1.0h - saturate(direction.y * 0.5h + 0.5h);
                half progress = saturate(_PulseProgress);
                half edgeWidth = max(_PulseEdgeWidth, 0.001h);
                half softness = max(_PulseSoftness * 0.5h, 0.001h);
                half pulseStarted = smoothstep(0.0h, softness, progress);

                half distanceToFront = abs(topDistance - progress);
                half edgeMask = 1.0h - smoothstep(edgeWidth, edgeWidth + softness, distanceToFront);

                // Keep the energy ring on the advancing front and disable it before the pulse starts.
                edgeMask *= smoothstep(progress - edgeWidth - softness, progress, topDistance);
                return saturate(edgeMask * pulseStarted);
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 encodedA = texCUBE(_TexA, i.texcoord);
                half4 encodedB = texCUBE(_TexB, i.texcoord);

                half3 decodedA = DecodeHDR(encodedA, _TexA_HDR);
                half3 decodedB = DecodeHDR(encodedB, _TexB_HDR);
                half3 direction = normalize(i.texcoord);
                half pulseBlend = GetPulseBlend(direction);
                half pulseEdge = GetPulseEdgeMask(direction);
                half reverseBlend = step(0.5h, _ReverseBlend);
                half3 source = lerp(decodedA, decodedB, reverseBlend);
                half3 target = lerp(decodedB, decodedA, reverseBlend);
                half3 blended = lerp(source, target, pulseBlend);

                blended *= _Tint.rgb * unity_ColorSpaceDouble.rgb;
                blended *= _Exposure;
                blended += _PulseEdgeColor.rgb * (_PulseEdgeIntensity * pulseEdge);

                return half4(blended, 1.0h);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
