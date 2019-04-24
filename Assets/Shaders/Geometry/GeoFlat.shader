// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/GeoFlat"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
    }
    SubShader
    {
        Tags{ "Queue"="Geometry" "RenderType"="Opaque" "LightMode"="ForwardBase" }
        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag

            float4 _Color;
            sampler2D _MainTex;

            struct v2g{
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 vertex: TEXCOORD1;
            };

            struct g2f {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float light: TEXCOORD1;
            };

            v2g vert(appdata_full v) {
                v2g o;
                o.vertex = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            [maxvertexcount(3)]
            void geo(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;

                // 面法線の計算
                float3 vecA = IN[1].vertex - IN[0].vertex;
                float3 vecB = IN[2].vertex - IN[0].vertex;
                float3 normal = cross(vecA, vecB);
                // 面法線をワールド座標系に直す
                normal = normalize(mul((float3x3) unity_ObjectToWorld, normal));

                // Direction Lightの向きを取得して正規化
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 面法線と光源の向きの内積を取得する
                o.light = max(0, dot(normal, lightDir));
                // UV座標は3つの頂点のUV座標の中点
                o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
                
                for(int i=0; i<3; i++) {
                    // 頂点は加工せずフラグメントシェーダへ
                    o.pos = IN[i].pos;
                    triStream.Append(o);
                }
            }

            half4 frag(g2f i) : COLOR {
                // テクスチャの色を取得する
                // このときのUV座標はジオメトリシェーダから取得したもの
                float4 col = tex2D(_MainTex, i.uv);
                // シェーディングを行う
                col.rgb *= i.light * _Color;
                return col;
            }
            ENDCG
        }
    }
}
