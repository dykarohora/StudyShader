Shader "Custom/Geometry/WireFrameReconstruction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(WireFrame)]
        _WidthFactor("Wireframe width factor", Range(0, 0.34)) = 0.05
        _Tint("Wireframe tint", Color) = (1,1,1,1)

        [Header(Reconstruction)]
        _PositionFactor("PositionFactor", Range(1.0, 6.0)) = 1.0
        _Reconstruction("Reconstruction", Range(0.0, 3.0)) = 0.0

        [Header(RimLighting)]
        _RimPower("Rim power", Range(0.1, 3)) = 1
        _RimAmplitude("Rim Amplitude", Range(0.1, 3)) = 1
        _RimTint("Rim tine", Color) = (1,1,1,1)

        [Header(Height)]
        _HeightMin("Min Height", Range(-3.0, 3.0)) = 0.0
        _HeightMax("Max Height", Range(-3.0, 3.0)) = 0.0
    }

    SubShader
    {

        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos: SV_POSITION;
                float3 bary: TEXCOORD0;
                float4 wpos: TEXCOORD1;
            };

            appdata vert(appdata v) {
                return v;
            }

            fixed _Reconstruction;
            float _PositionFactor;

            float _HeightMin;
            float _HeightMax;

            [maxvertexcount(3)]
            void geo(triangle appdata input[3], inout TriangleStream<g2f> triStream) {
                // ポリゴンのy軸位置を求める
                float4 center = (input[0].pos + input[1].pos + input[2].pos) / 3;
                float h = (mul(unity_ObjectToWorld, center).y - _HeightMin) / (_HeightMax - _HeightMin);
                // ちょっと補正
                h = pow(h, 1.8);

                // ポリゴンの面法線
                float3 vec1 = input[1].pos - input[0].pos;
                float3 vec2 = input[2].pos - input[0].pos;
                float3 normal = normalize(cross(vec1, vec2));
                
                g2f o;

                [unroll]
                for(int i=0; i<3; i++) {
                    appdata v = input[i];
                    v.pos.xyz += normal * saturate(1 - _Reconstruction) * _PositionFactor * h;
                    o.pos = UnityObjectToClipPos(v.pos);
                    if(i==0) {
                        o.bary = float3(1,0,0);
                    } else if(i==1) {
                        o.bary = float3(0,0,1);
                    } else {
                        o.bary = float3(0,1,0);
                    }
                    o.wpos = mul(unity_ObjectToWorld, v.pos);
                    triStream.Append(o); 
                }
                triStream.RestartStrip();
            }

            float _WidthFactor;
            fixed4 _Tint;

            fixed4 frag (g2f i) : SV_Target
            {
                if(!any(bool3(i.bary.x < _WidthFactor, i.bary.y < _WidthFactor, i.bary.z < _WidthFactor))) {
                    discard;
                }

                fixed4 col = _Tint;
                float h = (i.wpos.y - _HeightMin) / (_HeightMax - _HeightMin) - 0.2;
                col.a = saturate(_Reconstruction - h - 0.2);
                return col;
            }
            ENDCG
        }

        Pass {
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 wpos: TEXCOORD1;
                float3 normal: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed _Reconstruction;
            float _HeightMin;
            float _HeightMax;

            float _RimPower;
            float _RimAmplitude;
            float4 _RimTint;

            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wpos = mul(unity_ObjectToWorld, v.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i): SV_TARGET {
                //  リムライティング
                float3 normalDir = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
                float NNdotV = 1 - dot(normalDir, viewDir);
                float rim = pow(NNdotV, _RimPower) * _RimAmplitude;
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb = col.rgb * _RimTint.a + rim * _RimTint.rgb;

                float h = (i.wpos.y - _HeightMin) / (_HeightMax - _HeightMin) - 0.2;
                col.a = saturate(_Reconstruction - h - 0.9);
                return col;
            }
            ENDCG

        }
    }
}
