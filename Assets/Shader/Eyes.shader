Shader "Unlit/Eyes"
{
	Properties
	{
		_IrisRadius("瞳孔大小",Range(0.01,0.4)) = 0.225
		_IrisTex("rgb：瞳孔 a：遮罩", 2D) = "white" {}
		_ScleraTex("巩膜", 2D) = "white" {}
		_MixTex("rgb:frontnormal a:height", 2D) = "white" {}
		_RampTex("虹膜Ramp图", 2D) = "white" {}
		_RampTex0("巩膜Ramp图", 2D) = "white" {}

		_Distortion("瞳孔折射强度", Range(0,3)) = 3
		_PupilRadius("瞳孔尺寸", Range(0.01, 0.4)) = 0.3

		_Shininess("高光次幂", Range(1,100)) = 5
		_SpecularPower("高光强度", Range(0,3)) = 1
		_Offset("散射法线偏移", Range(0,3)) = 1
		_uvoff("uv偏移x,y", vector) = (0.0,0.0,0.0,0.0)

		_AmbientCol("环境光颜色", color) = (1.0,1.0,1.0,1.0)
	}

    SubShader
    {
		Pass{
		Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			float _IrisRadius;
			sampler2D _IrisTex;
			sampler2D _ScleraTex;float4 _ScleraTex_ST;
			sampler2D _MixTex;float4 _MixTex_ST;
			sampler2D _RampTex;
			sampler2D _RampTex0;
			float _Distortion;
			float _Shininess;
			float _SpecularPower;
			float _PupilRadius;
			float _Offset;
			float4 _uvoff;
			float4 _AmbientCol;
        
			struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
				//float4 tangent  : TANGENT;
            };
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 posWS : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float3 Causticnormal : TEXCOORD3;
				///float3 tDirWS : TEXCOORD5;
                //float3 bDirWS : TEXCOORD6; 
                //float3 nDirWS : TEXCOORD7; 
				half2 offset    : TEXCOORD4;
	        };

	        v2f vert(appdata_full v)
	        {
	        	v2f o;

	        	o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord+float2(_uvoff.x,_uvoff.y);
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				o.normal = v.normal;
				o.Causticnormal = -UnityObjectToWorldNormal(v.normal) + v.normal * _Offset;
				//o.tDirWS = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );//切线方向
                //o.bDirWS = normalize(cross(o.objectNormal, o.tDirWS) * v.tangent.w);                      //副切线方向
				//将视角向量变换到切线空间
                half3 viewDir = normalize(UnityWorldSpaceViewDir(o.posWS));
				TANGENT_SPACE_ROTATION;
                float2 BumpOffset = mul(rotation , viewDir).xy;
                //计算UV信息
                o.offset = BumpOffset;
	        	return o;
	        }

			float2 RemapUV(float2 uv)
			{
				float lengthUV = length(uv);
				float2 uvNormalized = uv / lengthUV ;
				float newLength = 0;
				if (lengthUV  < _PupilRadius) 
				{
					newLength = lengthUV / _PupilRadius * 0.14;
				} else
				{
					newLength = (lengthUV - _PupilRadius) / (0.5 - _PupilRadius) * 0.36 + 0.14;
				}
				return uvNormalized * newLength;
			}

	        fixed4 frag(v2f i): SV_Target
	        {
				
	        	float2 sUV = i.uv - float2(0.5, 0.5);

	        	float3 vDirWS = normalize( _WorldSpaceCameraPos.xyz - i.posWS);
	        	float3 vDirOS = normalize(mul(unity_WorldToObject, vDirWS));
				half3 lDirWS = normalize (_WorldSpaceLightPos0.xyz);

	        	float2 sUVIris = sUV / _IrisRadius / 2;//控制瞳孔缩放

				//计算高度遮罩
	        	float d1 = sqrt(1 - sUVIris.x * sUVIris.x - sUVIris.y * sUVIris.y) - 0.86603;
	        	float d2 = sqrt(0.3025 - sUVIris.x * sUVIris.x - sUVIris.y * sUVIris.y) - 0.22913;
	        	float2 height = _Distortion * (d2 - d1);
				//视差简单模拟折射
				float2 uvIris = RemapUV(sUVIris  + i.offset * height);
	        	float irisMask = tex2D(_IrisTex, uvIris + float2(0.5,0.5)).a;
				if (length(uvIris) > 0.5) irisMask = 0;
				
				half4 var_IrisTex = tex2D(_IrisTex, uvIris + float2(0.5,0.5));
	         	float4 col = lerp(tex2D(_ScleraTex, i.uv * _ScleraTex_ST.xy + _ScleraTex_ST.zw), var_IrisTex, irisMask);
				float3 CausticNormal = normalize(lerp(i.normal,i.Causticnormal,irisMask));
				//光照模型
				
				//高光
				_WorldSpaceLightPos0.y -= 0.5;//修正高光位置
	         	float3 lDirOS =  - normalize(mul(unity_WorldToObject,_WorldSpaceLightPos0.xyz));
	         	float3 specu = pow(max(0.0, dot(reflect(lDirOS, i.normal),vDirOS)), _Shininess) * _SpecularPower * _LightColor0.rgb;
				
	         	if (length(sUV) > _IrisRadius) col = tex2D(_ScleraTex, i.uv * _ScleraTex_ST.xy + _ScleraTex_ST.zw);
				//漫反射
				half lambert = dot(CausticNormal,lDirWS);
				half3 sss = tex2D(_RampTex, float2(lambert,0.6));
				half3 sss0 = tex2D(_RampTex0, float2(lambert,0.6));
				half3 diff = _AmbientCol * sss0 *col.rgb;
				if (length(irisMask) > 0.8) diff = _AmbientCol * sss *col.rgb;
				//混合
				half4 finalRGB = float4(specu + diff,1.0);
	        	return finalRGB;
	        	//return half4(specu,1.0);
	        }
        	ENDCG
        }

       
 	}
    //FallBack "Diffuse"
}