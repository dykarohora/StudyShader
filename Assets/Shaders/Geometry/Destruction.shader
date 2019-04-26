Shader "Custom/Geometry/Destruction"
{
    Properties
    {
        [KeywordEnum(Property, Camera)]
        _Method("DestructionMethod", Float) = 0
        _TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _MainTex("Particle Texture", 2D) = "white" {}
        _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
        _Destruction("Destruction Factor", Range(0.0, 1.0)) = 0.0
        _PositionFactor("Position Factor", Range(0.0, 1.0)) = 0.2
        _RotationFactor("Rotation Factor", Range(0.0, 1.0)) = 1.0
        _ScaleFactor("Scale Factor", Range(0.0, 1.0)) = 1.0
        _AlphaFactor("Alpha Factor", Range(0.0, 1.0)) = 1.0
        _StartDistance("Start Distance", Float) = 0.6
        _EndDistance("End Distance", Float) = 0.3
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
        }

        Blend SrcAlpha One
        LOD 100

        Pass
        {
            CGPROGRAM

            
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            #define PI 3.1415926535

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed4 _TintColor;

            fixed _InvFade;
            fixed _Destruction;
            fixed _PositionFactor;
            fixed _RotationFactor;
            fixed _ScaleFactor;
            fixed _AlphaFactor;
            fixed _StartDistance;
            fixed _EndDistance;

            struct appdata_t
            {
                float4 vertex: POSITION;
                fixed4 color: COLOR;
                float2 texcoord: TEXCOORD0;
            };

            struct g2f
            {
                float4 vertex: SV_POSITION;
                fixed4 color: COLOR;
                float2 texcoord: TEXCOORD0;
            };

            inline float rand(float2 seed)
            {
                return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            appdata_t vert (appdata_t v)
            {
                return v;
            }

            [maxvertexcount(3)]
            void geom(triangle appdata_t input[3], inout TriangleStream<g2f> stream) {
                // ポリゴンの中央を計算する
                float3 center = (input[0].vertex + input[1].vertex + input[2].vertex).xyz / 3;
                // ポリゴンの面法線を計算する
                float3 vec1 = input[1].vertex - input[0].vertex;
                float3 vec2 = input[2].vertex - input[0].vertex;
                float3 normal = normalize(cross(vec1, vec2));

                fixed destruction = _Destruction;

                fixed r = 2 * (rand(center.xy) - 0.5);
                fixed3 r3 = fixed3(r,r,r);

                [unroll]
                for(int i=0; i<3; ++i) {
                    appdata_t v = input[i];

                    g2f o;
                    // 法線方向に頂点を移動する
                    v.vertex.xyz += normal * destruction * _PositionFactor * r3;
                    o.vertex = UnityObjectToClipPos(v.vertex);

                    o.color = v.color;
                    o.color.a *= 1.0 - destruction * _AlphaFactor;
                    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                    stream.Append(o);
                }
                stream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = 2.0 * i.color * _TintColor * tex2D(_MainTex, i.texcoord);
                return col;
            }
            ENDCG
        }
    }
}
