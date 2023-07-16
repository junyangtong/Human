Shader "Skin"
{
    Properties
    {	
		_Tint("染色", Color) = (1 ,1 ,1 ,1)
        _MainTex ("基础色贴图", 2D) = "white" {}
		_NormalTex ("法线贴图", 2D) =  "bump" {}
		_DepthMap ("细节贴图", 2D) =  "gray" {}
		_MixTex("r:厚度g：曲率a：环境光遮蔽ao", 2D) =  "gray" {}
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_MetallicInt ("Metallic", Range(0, 1)) = 0.5
        _btdfpow ("透射强度", Range(0, 10)) = 0.5
		_btdfscale("透射范围", Range(0, 10)) = 0.5
		_btdfDistortion("透射偏移", Range(0, 1)) = 0.5
		[HDR]_btdfCol("透射颜色", Color) = (1 ,1 ,1 ,1)
		_LUT("LUT", 2D) = "white" {}
		_SSSLUT ("SSSLUT", 2D) = "white" {}
		_beckmannTex("beckmannLUT", 2D) = "white" {}
		_SkinSpecInt1("皮肤第一层高光强度", Range(0, 1)) = 0.5
		_SkinSpecInt2("皮肤第二层高光强度", Range(0, 1)) = 0.5
		////sss

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		
        Pass
        {
			Tags {
				"LightMode" = "ForwardBase"
			}
            CGPROGRAM
			
			#include "AutoLight.cginc"   
            #include "Lighting.cginc"
			#pragma target 3.0
			#pragma multi_compile_fwdbase_fullshadows
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityStandardBRDF.cginc" 
			//引入cginc库
			#include "Main.cginc"
            ENDCG
        }

    }
	FallBack "Diffuse"
}
