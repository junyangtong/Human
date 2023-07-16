Shader "Hair"
{
    Properties
    {	
        _Tint("Tint", Color) = (1 ,1 ,1 ,1)
        _MainTex ("_MainTex", 2D) = "white" {}
		_NormalTex ("_Normal", 2D) =  "bump" {}
		_Flowmap ("_Flowmap", 2D) =  "bump" {}
		_MixTex("a：环境光遮蔽ao", 2D) =  "gray" {}
        _MetallicInt ("_MetallicInt", Range(0, 1)) = 0.5
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
        [Header(KajiyaKay)]
        _Specular("_Specular", Range(0, 1)) = 0.5
        _SpecularInt1("_SpecularInt1", Range(0, 1000)) = 0.5
        _SpecularInt2("_SpecularInt2", Range(0, 1000)) = 0.5
        _SpecShift1("_SpecShift1", Range(-5, 5)) = 0.5
        _SpecShift2("_SpecShift2", Range(-5, 5)) = 0.5
        _SpecularColor1("_SpecularColor1", color) = (1.0,1.0,1.0,1.0)
        _SpecularColor2("_SpecularColor2", color) = (1.0,1.0,1.0,1.0)
        [Header(Sss)]
        _WarpNDL("头发sss（fake）", Range(0, 1)) = 0.5
        _scatterColor("sss散射颜色" , Color) = (1.0 , 1.0 , 1.0 , 1.0) 
        [Header(Btdf)]
        _btdfpow ("透射强度", Range(0, 10)) = 0.5
		_btdfscale("透射范围", Range(0, 10)) = 0.5
		_btdfDistortion("透射偏移", Range(0, 1)) = 0.5
		[HDR]_btdfCol("透射颜色", Color) = (1 ,1 ,1 ,1)
        _LUT("LUT", 2D) = "white" {}
        _Cutoff("透明剪切", Range(0, 1)) = 0.5
        _Color("Color" , Color) = (1.0 , 1.0 , 1.0 , 1.0) //回调的阴影Pass需要用到，本Pass无用到，所以下面的Pass不用定义
        

    }

        
    
    SubShader
    {   //渲染透明剪切部分
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
                "RenderType"="Opaque"
            }
            Cull Off   //开启双面显示
            CGPROGRAM
            //投影需要的
            #include "AutoLight.cginc"   
            #include "Lighting.cginc"
            //
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
			#include "UnityStandardBRDF.cginc" 
			//引入cginc库
			#include "Hairclip.cginc"
            ENDCG
        }
        //渲染半透明背面
        Pass
        {
			Tags {
				"LightMode" = "ForwardBase"
                 "Queue"="Transparent"               //调整渲染顺序
                 "RenderType"="transparent"    //渲染方式改为cutout
                 "ForceNoshadowCasting"="ture"       //关闭阴影投射
                "IngnoreProjector"="ture"           //不影响投射器
			}
            Cull Front
            ZWrite Off
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
			#include "Hairblend.cginc"
            ENDCG
        }
        //渲染半透明正面
        Pass
        {
			Tags {
				"LightMode" = "ForwardBase"
                 "Queue"="Transparent"               //调整渲染顺序
                 "RenderType"="transparent"    //渲染方式改为cutout
                 "ForceNoshadowCasting"="ture"       //关闭阴影投射
                "IngnoreProjector"="ture"           //不影响投射器
			}
            Cull Back
            ZWrite Off
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
			#include "Hairblend.cginc"
            ENDCG
        }

    }
    FallBack "Legacy Shaders/Transparent/Cutout/VertexLit"
}