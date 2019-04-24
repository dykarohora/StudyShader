Shader "Custom/Reflection/Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ambient ("Ambient", Range(0,1)) = 0
        _SpecColor("Specular Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _LightColor0;
            float4 _SpecColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal: TEXCOORD1;
                float3 worldPos: TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                // 頂点法線と頂点座標をワールド空間座標系に変換する
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 頂点法線
                float3 normal = normalize(i.worldNormal);

                // ライト方向のベクトル(ディレクションライトの方向ベクトル)
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float NdotL = dot(normal, lightDir);

                // カメラの方向ベクトル(頂点からカメラへのベクトル)
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float NdotV = dot(normal, viewDir);
                
                // 拡散色(Diffuse)
                float4 tex = tex2D(_MainTex, i.uv);
                float diffusePower = max(0, NdotL);
                float4 diffuse = diffusePower * tex * _LightColor0;

                // 反射光ベクトル
                float3 R = -1 * lightDir + 2.0 * NdotL * normal;
                float VdotR = dot (viewDir, R);
                float3 specularPower = pow(max(0, VdotR), 10.0);
                
                float4 specular = float4(specularPower, 1.0) * _SpecColor * _LightColor0;

                fixed4 color = diffuse + specular;
                return color;
            }
            ENDCG
        }
    }
}
