﻿Shader "Custom/Geometry/WireFrameUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(WireFrame)]
        _Color ("Color", Color) = (1,1,1,1)
        _Width ("Width", Range(0.001, 0.01)) = 0.005

        [Header(Surface)] 
        _Tint ("Tint", Color) = (1,1,1,1)

        [Header(Local)]
        _HeightOffset("Height Offset", Range(0,1)) = 0
        _HeightPower("Height Power", Float) = 0

        [Header(Rim)]
        _RimPower ("Rim Power", Range(0.1, 3)) = 1
        _RimAmplitude ("Rim Amplitude", Range(0.1, 3)) = 1
        _RimTint ("Rim Tint", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Transpanret" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2g {
                float4 vertex: POSITION;
                float4 color: TEXCOORD0;
            };

            struct g2f {
                float4 vertex: SV_POSITION;
                float4 color: TEXCOORD0;
            };

            float4 _Color;
            float _Width;

            v2g vert (appdata v)
            {
                // 頂点シェーダでは何もしない
                v2g o;
                o.vertex = v.vertex;
                o.color = v.color;
                return o;
            }

            [maxvertexcount(18)]
            void geo(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                for(int i = 0; i<3; i++) {
                    v2g vb = IN[(i+0) % 3];
                    v2g v1 = IN[(i+1) % 3];
                    v2g v2 = IN[(i+2) % 3];

                    // ベース頂点から、ほか2点の中点への単位ベクトル
                    float3 dir = normalize((v1.vertex.xyz + v2.vertex.xyz) * 0.5 - vb.vertex.xyz);

                    g2f o;
                    o.color = _Color * IN[0].color;
                    // ベース頂点以外の頂点を上で求めたベクトル方向に伸ばした頂点を使ってポリゴンを作るイメージ
                    o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz, 1));
                    triStream.Append(o);   

                    o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz, 1));
                    triStream.Append(o);   
                    
                    o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz + dir * _Width, 1));
                    triStream.Append(o);
                    triStream.RestartStrip();

                    o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz, 1));
                    triStream.Append(o);   

                    o.vertex = UnityObjectToClipPos(float4(v1.vertex.xyz + dir * _Width, 1));
                    triStream.Append(o);   
                    
                    o.vertex = UnityObjectToClipPos(float4(v2.vertex.xyz + dir * _Width, 1));
                    triStream.Append(o);
                    triStream.RestartStrip();
                }
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = i.color;
                return col;
            }
            ENDCG
        }

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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color: COLOR;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 wpos: TEXCOORD1;
                float4 color: TEXCOORD2;
                float3 normal: TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            // オブジェクトのワールド座標
            // スクリプトから与える
            float4 _WorldPosition;

            float4 _Tint;
            float _HeightOffset;
            float _HeightPower;

            float _RimPower;
            float _RimAmplitude;
            float4 _RimTint;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.color = v.color;
                o.normal = v.normal;
                return o;
            }

            // 頂点シェーダでよくね？
            [maxvertexcount(3)]
            void geo(triangle v2f v[3], inout TriangleStream<v2f> TriStream) {
                for(int i = 0; i<3; i++) {
                    v2f o = v[i];
                    // 頂点と法線をワールド空間に変換
                    o.vertex = UnityObjectToClipPos(v[i].vertex);
                    o.normal = UnityObjectToWorldNormal(v[i].normal);

                    TriStream.Append(o);
                }
                TriStream.RestartStrip();
            }

            float halpha(float y) {
                return pow(y + _HeightOffset, _HeightPower);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // リムライティング
                // 法線
                float3 normalDir = normalize(i.normal);
                // 頂点からカメラへの方向ベクトル
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
                // モデルの縁を光らせたいので、法線と視線の内積から光量を計算する
                float NNdotV = 1 - dot(normalDir, viewDir);
                float rim = pow(NNdotV, _RimPower) * _RimAmplitude; 
                // テクスチャカラーを取得して、頂点カラーとパラメータで指定した色合いを乗ずる
                fixed4 col = tex2D(_MainTex, i.uv) * i.color * _Tint;
                // リムライトの色合いを重ねる
                col.rgb = col.rgb * _RimTint.a + rim * _RimTint.rgb;                
                
                col.a = saturate(halpha(i.wpos.y - _WorldPosition.y));
                
                return col;
            }
            ENDCG
        }
    }
}
