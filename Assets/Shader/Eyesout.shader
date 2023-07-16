Shader "Eyesout"
{
    Properties
    {
        _Tint("Tint", Color) = (1 ,1 ,1 ,1)
        _MetallicInt ("_MetallicInt", Range(0, 1)) = 0.5
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_Opacity     ("不透明度" , Range(0.0 , 1.0))= 1.0
        _Cubemap ("环境球", Cube) = "_Skybox" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags {
            "Queue"="Transparent"               //调整渲染顺序
            "RenderType"="transparentCutout"    //渲染方式改为cutout
            "ForceNoshadowCasting"="ture"       //关闭阴影投射
            "IngnoreProjector"="ture"           //不影响投射器
        }
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
			
			#include "AutoLight.cginc"   
            #include "Lighting.cginc"
			#pragma target 3.0
			#pragma multi_compile_fwdbase_fullshadows
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityStandardBRDF.cginc" 
			//引入cginc库
			#include "Eyesout.cginc"
            ENDCG
        }

    }
	FallBack "Diffuse"
}
