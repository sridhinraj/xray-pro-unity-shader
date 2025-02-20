Shader "Custom/XRayClippingShader_Transparent"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _MainTex("Base Color Map", 2D) = "white" {}
        [Toggle]_UseMainTex("Use Base Color Map", Float) = 1.0

        _Roughness("Roughness", Range(0, 1)) = 0.5
        _RoughnessMap("Roughness Map", 2D) = "white" {}
        [Toggle]_UseRoughnessMap("Use Roughness Map", Float) = 1.0

        _Metallic("Metallic", Range(0, 1)) = 0.5
        _MetallicMap("Metallic Map", 2D) = "white" {}
        [Toggle]_UseMetallicMap("Use Metallic Map", Float) = 1.0

        [HDR]_EmissionColor("Emission Color", Color) = (0, 0, 0, 1)
        _EmissiveMap("Emissive Map", 2D) = "black" {}
        [Toggle]_UseEmissiveMap("Use Emissive Map", Float) = 1.0

        _NormalMap("Normal Map", 2D) = "bump" {}
        [Toggle]_UseNormalMap("Use Normal Map", Float) = 1.0

        _AOMap("Ambient Occlusion Map", 2D) = "white" {}
        [Toggle]_UseAOMap("Use AO Map", Float) = 1.0

        _Opacity("Opacity", Range(0, 1)) = 1.0
        _OpacityMap("Opacity Map", 2D) = "white" {}
        [Toggle]_UseOpacityMap("Use Opacity Map", Float) = 1.0

        _ClipPlanePos("Clip Plane Position", Vector) = (0, 0, 0, 1)
        _ClipPlaneNormal("Clip Plane Normal", Vector) = (0, 1, 0, 0)

        _AlphaClipThreshold("Alpha Clip Threshold", Range(0, 1)) = 0.5

        _DarkenFactor("Darken Factor", Range(0, 1)) = 0.0 // Darkening factor
        _BrightenFactor("Brighten Factor", Range(0, 2)) = 1.0 // Brightening factor
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha // Alpha blending
        ZWrite Off // Disable depth writing for transparency

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _BaseColor;
            sampler2D _MainTex;
            float _UseMainTex;

            float _Roughness;
            sampler2D _RoughnessMap;
            float _UseRoughnessMap;

            float _Metallic;
            sampler2D _MetallicMap;
            float _UseMetallicMap;

            float4 _EmissionColor;
            sampler2D _EmissiveMap;
            float _UseEmissiveMap;

            sampler2D _NormalMap;
            float _UseNormalMap;

            sampler2D _AOMap;
            float _UseAOMap;

            float _Opacity;
            sampler2D _OpacityMap;
            float _UseOpacityMap;

            float4 _ClipPlanePos;
            float4 _ClipPlaneNormal;
            float _AlphaClipThreshold;

            float _DarkenFactor;
            float _BrightenFactor; // New brighten factor

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                o.viewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Base Color
                float4 baseColor = _BaseColor;
                if (_UseMainTex > 0.5)
                    baseColor *= tex2D(_MainTex, i.uv);

                // Opacity handling
                float opacity = _Opacity;
                if (_UseOpacityMap > 0.5)
                    opacity *= tex2D(_OpacityMap, i.uv).r;
                baseColor.a *= opacity;

                // Roughness
                float roughness = _Roughness;
                if (_UseRoughnessMap > 0.5)
                    roughness = tex2D(_RoughnessMap, i.uv).r;

                // Metallic
                float metallic = _Metallic;
                if (_UseMetallicMap > 0.5)
                    metallic = tex2D(_MetallicMap, i.uv).r;

                // Emission
                float3 emissive = _EmissionColor.rgb;
                if (_UseEmissiveMap > 0.5)
                    emissive *= tex2D(_EmissiveMap, i.uv).rgb;

                // Normal map
                float3 normal = normalize(i.normal);
                if (_UseNormalMap > 0.5)
                {
                    float3 normalTex = UnpackNormal(tex2D(_NormalMap, i.uv));
                    normal = normalize(mul(normalTex, (float3x3)unity_ObjectToWorld));
                }

                // Light direction and view direction
                float3 V = normalize(i.viewDir);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);

                // Halfway vector
                float3 H = normalize(L + V);

                // Fresnel term
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), baseColor.rgb, metallic);
                float3 F = F0 + (1.0 - F0) * pow(1.0 - max(dot(H, V), 0.0), 5.0);

                // Diffuse lighting
                float NdotL = max(dot(normal, L), 0.0);
                float3 diffuse = baseColor.rgb * NdotL;

                // Specular reflection
                float NdotV = max(dot(normal, V), 0.0);
                float D = roughness * roughness;
                float denom = (NdotV * (1.0 - D) + D) * (NdotL * (1.0 - D) + D);
                float3 specular = D * F / denom;

                // Ambient Occlusion
                float ao = 1.0;
                if (_UseAOMap > 0.5)
                    ao = tex2D(_AOMap, i.uv).r;

                // Final color calculation
                float3 finalColor = (diffuse + specular + emissive) * ao;

                // Clip plane logic
                float dist = dot(i.worldPos - _ClipPlanePos.xyz, _ClipPlaneNormal.xyz);
                if (dist < 0 || baseColor.a < _AlphaClipThreshold)
                    discard;

                // Apply darken effect
                finalColor *= (1.0 - _DarkenFactor); 

                // Apply brightness effect
                finalColor *= _BrightenFactor; 

                return float4(finalColor, baseColor.a); // Return color with proper alpha
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
