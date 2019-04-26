Shader "Custom/Geometry/WireFrameReconstruction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(WireFrame)]
        _WidthFactor("Wireframe width factor", Range(0, 0.34)) = 0.05
        _Tint("Wireframe tint", Color) = (1,1,1,1)

        [Header(Reconstruction)]
        _PositionFactor("PositionFactor", Range(0.0, 1.0)) = 0.2
        _Reconstruction("Reconstruction", Range(0.0, 2.0)) = 0.0
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

            [maxvertexcount(3)]
            void geo(triangle appdata input[3], inout TriangleStream<g2f> triStream) {
                // ポリゴンの中心
                float3 center = (input[0].pos + input[1].pos + input[2].pos).xyz / 3;
                // ポリゴンの面法線
                float3 vec1 = input[1].pos - input[0].pos;
                float3 vec2 = input[2].pos - input[0].pos;
                float3 normal = normalize(cross(vec1, vec2));


                g2f o;

                appdata v0 = input[0];
                float h = mul(unity_ObjectToWorld, v0.pos).y;
                h = pow(h, 1.5);

                v0.pos.xyz += normal * saturate(1 - _Reconstruction) * h;
                o.pos = UnityObjectToClipPos(v0.pos);
                o.bary = float3(1,0,0);
                o.wpos = mul(unity_ObjectToWorld, input[0].pos);
                triStream.Append(o);

                appdata v1 = input[1];
                v1.pos.xyz += normal * saturate(1 - _Reconstruction) * h;
                o.pos = UnityObjectToClipPos(v1.pos);
                o.bary = float3(0,0,1);
                o.wpos = mul(unity_ObjectToWorld, input[1].pos);
                triStream.Append(o);
                
                appdata v2 = input[2];
                v2.pos.xyz += normal * saturate(1 - _Reconstruction) * h;
                o.pos = UnityObjectToClipPos(v2.pos);
                o.bary = float3(0,1,0);
                o.wpos = mul(unity_ObjectToWorld, input[2].pos);
                triStream.Append(o);

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
                col.a = saturate(pow(i.wpos.y - saturate(1-_Reconstruction), 2));
                return col;
            }
            ENDCG
        }
    }
}
