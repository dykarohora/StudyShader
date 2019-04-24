Shader "Custom/Geometry/GeoExtrude"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Factor("Factor", Range(0.0, 2.0)) = 0.2
    }
    SubShader
    {
        Tags {"RenderType"="Opaque"}
        Cull Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo

            #include "UnityCG.cginc"

            struct v2g {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct g2f {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                fixed4 col: COLOR;
            };

            // テクスチャ
            sampler2D _MainTex;
            // タイリングとオフセット
            float4 _MainTex_ST;

            v2g vert(appdata_base v) {
                v2g o;
                // 頂点はモデル空間のまま次のステージへ渡す。
                o.vertex = v.vertex;
                // タイリングとオフセットを考慮したUV座標を取得する。
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                // 頂点法線はモデル空間のまま次のステージへ渡す。
                o.normal = v.normal;
                return o;
            }

            // 係数
            float _Factor;
            
            [maxvertexcount(24)]
            void geo(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;

                // 面法線を計算する
                float3 edgeA = IN[1].vertex - IN[0].vertex;
                float3 edgeB = IN[2].vertex - IN[0].vertex;
                float3 normalFace = normalize(cross(edgeA, edgeB));

                // ここで18頂点新しく作る
                // ポリゴンを伸ばしたところの側面
                for(int i=0; i<3; i++) {
                    // Proc.1
                    // ベース頂点をクリップ空間系に変換
                    o.pos = UnityObjectToClipPos(IN[i].vertex);
                    // UV座標は頂点のものをそのまま
                    o.uv = IN[i].uv;
                    // 色は黒
                    o.col = fixed4(0.,0.,0.,1.);
                    triStream.Append(o);

                    // ベース頂点から面法線に係数を乗じたものを新しい頂点として作成
                    o.pos = UnityObjectToClipPos(IN[i].vertex + float4(normalFace, 0) * _Factor);
                    // UV座標はベース頂点のものをそのまま
                    o.uv = IN[i].uv;
                    // 色は白
                    o.col = fixed4(1,1,1,1);
                    triStream.Append(o);

                    int inext = (i+1)%3;    // 1st: 1, 2nd: 2, 3rd 0

                    // 隣の頂点
                    o.pos = UnityObjectToClipPos(IN[inext].vertex);
                    o.uv = IN[inext].uv;
                    o.col = fixed4(0.,0.,0.,1.);
                    triStream.Append(o);

                    triStream.RestartStrip();

                    // Proc.2
                    o.pos = UnityObjectToClipPos(IN[i].vertex + float4(normalFace, 0) * _Factor);
                    o.uv = IN[i].uv;
                    o.col = fixed4(1,1,1,1);
                    triStream.Append(o);

                    o.pos = UnityObjectToClipPos(IN[inext].vertex);
                    o.uv = IN[inext].uv;
                    o.col = fixed4(0.,0.,0.,1.);
                    triStream.Append(o);

                    o.pos = UnityObjectToClipPos(IN[inext].vertex + float4(normalFace, 0) * _Factor);
                    o.uv = IN[inext].uv;
                    o.col = fixed4(1,1,1,1);
                    triStream.Append(o);

                    triStream.RestartStrip();
                }

                // ここで3頂点
                for(int i=0; i<3; i++) {
                    o.pos = UnityObjectToClipPos(IN[i].vertex + float4(normalFace, 0) * _Factor);
                    o.uv = IN[i].uv;
                    o.col = fixed4(1,1,1,1);
                    triStream.Append(o);
                }
                triStream.RestartStrip();

                
                // ここで3頂点
                for(int i=0; i<3; i++) {
                    o.pos = UnityObjectToClipPos(IN[i].vertex);
                    o.uv = IN[i].uv;
                    o.col = fixed4(0.,0.,0.,1.);
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            fixed4 frag(g2f i): SV_TARGET {
                fixed4 col = tex2D(_MainTex, i.uv) * i.col;
                return col;
            }
            ENDCG
        }
    }
}
