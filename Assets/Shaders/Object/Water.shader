Shader "Custom/Object/Water"
{
    Properties {
        _Color("Color", Color) = (1,1,1,1)
        _NoiseTex("Noise Texture", 2D) = "white" {}
        // 波の動く速さ
        _WaveSpeed("Wave Speed", Range(100, 500)) = 100
        // 波の揺れの強さ
        _WaveAmp("Wave Amp", Range(0.1,0.3)) = 0.2
        _ExtraHeight("Extra Height", Range(-2.0, 2.0)) = 0.0

        _DepthRampTex("Depth Ramp", 2D) = "white" {}
        _DepthFactor("Depth Factor", Range(0.0,2.0)) = 1.0
    }
    SubShader {
        Tags {
            "Queue"="Transparent"
        }

        Pass {
            // 
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            float4 _Color;

            sampler2D _NoiseTex;
            float _WaveSpeed;
            float _WaveAmp;

            float _ExtraHeight;

            sampler2D _CameraDepthTexture;
            sampler2D _DepthRampTex;
            float _DepthFactor;

            struct vertexInput {
                float4 vertex: POSITION;
                float4 uv: TEXCOORD0;
            };

            struct vertexOutput {
                float4 pos: SV_POSITION;
                float4 uv: TEXCOORD0;
                float4 screenPos: TEXCOORD1;
            };

            vertexOutput vert(vertexInput input) {
                vertexOutput output;
                // 頂点をクリップ空間に変換
                output.pos = UnityObjectToClipPos(input.vertex);

                // 白黒ノイズ画像からサンプリング（白黒なので1チャネルだけでOK）
                float noiseSample = tex2Dlod(_NoiseTex, float4(input.uv.xy, 0, 0));
                // 頂点をy軸 x軸方向に-1〜1の範囲でずらす。
                // ずらし具合はsin波、cos波
                output.pos.y += sin(_Time*_WaveSpeed*noiseSample) * _WaveAmp + sin(_Time*35) * _ExtraHeight;
                output.pos.x += cos(_Time*_WaveSpeed*noiseSample) * _WaveAmp;
                // スクリーン座標を取得
                output.screenPos = ComputeScreenPos(output.pos);
                output.uv = input.uv;
                return output;
            }

            fixed4 frag(vertexOutput input): SV_TARGET {
                				// apply depth texture
				float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
				float depth = LinearEyeDepth(depthSample).r;

				// create foamline
				float foamLine = 1 - saturate(_DepthFactor * (depth - input.screenPos.w));
				float4 foamRamp = float4(tex2D(_DepthRampTex, float2(foamLine, 0.5)).rgb, 1.0);

                float4 col = _Color * foamRamp;
                return col;
            }
            ENDCG
        }
    }
}
