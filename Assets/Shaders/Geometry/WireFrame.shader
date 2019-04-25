Shader "Custom/Geometry/WireFrame"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(WireFrame)]
        _Color("Color", Color) = (1,1,1,1)
        _Width ("Width", Range(0.001, 0.1)) = 0.005
    }
    SubShader
    {
        Tags { "RenderType"="Transpanret" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 4.0
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            #pragma multi_compile_fog
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
                UNITY_FOG_COORDS(1)
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
    }
}
