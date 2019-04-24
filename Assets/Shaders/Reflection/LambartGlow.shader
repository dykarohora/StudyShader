Shader "Custom/Reflection/LambartGlow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float diffuse: COLOR0;
            };

            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                // 頂点をクリップ座標系に変換
                o.vertex = UnityObjectToClipPos(v.vertex);
                // UV座標はそのままｍ
                o.uv = v.uv;

                // 頂点法線
                float3 normal = v.normal;
                // 頂点に対する光源ベクトルを取得する
                float3 lightDir = normalize(ObjSpaceLightDir(v.vertex));
                // 内積を取る
                float NdotL = dot(normal, lightDir);
                // 負値は丸める
                o.diffuse = max(0, NdotL);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 tex = tex2D(_MainTex, i.uv);
                fixed4 color = i.diffuse * tex;
                return color;
            }
            ENDCG
        }
    }
}
