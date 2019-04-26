// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Geometry/WireframeAlt"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [PowerSlider(3.0)]
        _WireframeVal ("Wireframe width", Range(0., 0.34)) = 0.05
        _FrontColor("Front color", Color) = (1,1,1,1)
        _BackColor("Back color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2g {
                float4 pos: SV_POSITION;
            };

            struct g2f {
                float4 pos: SV_POSITION;
                float3 bary: TEXCOORD0;
            };

            v2g vert(appdata_base v) {
                v2g o;
                // 頂点をワールド空間座標系に変換する
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;
                o.pos = IN[0].pos;
                o.bary = float3(1,0,0);
                triStream.Append(o);
                o.pos = IN[1].pos;
                o.bary = float3(0,1,0);
                triStream.Append(o);
                o.pos = IN[2].pos;
                o.bary = float3(0,0,1);
                triStream.Append(o);
            }

            float _WireframeVal;
            fixed4 _BackColor;

            fixed4 frag(g2f i) : SV_Target {
                // baryは線形補間される
                // 頂点を結ぶ直線上ならば、いずれかは0
                if(!any(bool3(i.bary.x < _WireframeVal, i.bary.y < _WireframeVal, i.bary.z < _WireframeVal))) {
                    discard;
                }
                return _BackColor;
            }
            ENDCG
        }
    }
}
