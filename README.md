# Human
sss皮肤、眼球、头发的渲染

一、皮肤渲染
 实现次表面散射


![image](https://github.com/junyangtong/Human/assets/135015047/8a1d62d0-dc75-472c-b2b4-6cbe1bde67e6)


什么是次表面散射？
次表面散射其实就是复杂版本的漫反射
如上图，光线从一种介质射向另外一种介质时，有反射，次表面散射、透射三种交互形态：
- 其普通反射的行为用BRDF描述
- 其次表现散射的行为用 BSSRDF描述
- 其透射的行为用BTDF描述
四者的联系：
- 总体来说，BRDF 为 BSSRDF 的一种简化
- BSDF可分为反射和透射分量两部分，即BSDF = BRDF + BTDF

【《Real-Time Rendering 3rd》 提炼总结】(六) 第七章 · 高级着色：BRDF及相关技术
https://zhuanlan.zhihu.com/p/28059221

预积分次表面散射
这里用预积分次表面散射的方式来表现次表面散射的效果
什么是预积分次表面散射：预积分的皮肤着色（Pre-Integrated Skin Shading），其实是一个从结果反推实现的方案，具体思路是把次表面散射的效果预计算成一张二维查找表，查找表的参数分别是dot(N,L)和曲率，因为这两者结合就能够反映出光照随着曲率的变化。
预积分我的理解就是把可能出现的次表面散射情况都计算好储存在一张lut图中，只需要通过dot(N,L)和曲率查找就可以了
如BSSDF方程所示，如果要考虑SSS效果，并得到某一个点处沿着某个方向发射的光强度，那么就得老老实实对整个区域的每个点积分，这显然非常的“昂贵”。因此自然有人开始尝试预积分技术，将BSSDF的部分或整体预先计算出来，并以一定方式保存进纹理。
 
生成一张lut图

![image](https://github.com/junyangtong/Human/assets/135015047/62bb8e79-e89d-4321-88f2-0b156cf3de6a)

预积分皮肤渲染LUT生成实践
https://zhuanlan.zhihu.com/p/72161323
计算查找参数
在SP中烘焙的曲率贴图，在ps中进行了模糊处理并且将耳朵等比较薄的部分提亮了。

![image](https://github.com/junyangtong/Human/assets/135015047/9dfe2019-4a21-4ae6-94da-64e04b632495)

下面是代码
half3 sss = tex2D(_SSSLUT, float2(halfLambert, curvature));
结合到BRDF中，实现效果如下

![image](https://github.com/junyangtong/Human/assets/135015047/2b803ac1-08bc-413b-bf54-34c86be00142)


透射
透射基于unity的实现
https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-2/
1.计算物体背面的光照

![image](https://github.com/junyangtong/Human/assets/135015047/03dafd4a-69ec-43e5-b695-9bae193bd557)

使用兰伯特，将光方向L进行反向
使用_Distortion作为控制参数，修正光的方向
[图片]
2.在SP中烘焙厚度图 thickness map
[图片]
*thickness结合厚度图，*_Attenuation是考虑了光照衰减
[图片]
实现效果
[图片]
此方法不完全基于物理只是一种基于经验的近似，消耗一张thickness map以及少量计算
皮肤高光

![image](https://github.com/junyangtong/Human/assets/135015047/9bae3b81-a256-4352-bad3-54038bfd329c)

[图片]
[图片]
其他
眉毛遮罩
[图片]
ao混合basecol
[图片]


二、眼睛渲染
虹膜大小调整
这里将模型自带的UV首先转换成关于原点中心对称，比较方便计算。然后将UV到原点长度大于设定值的返回巩膜颜色，小于设定值的我们做虹膜的渲染，并且使用一个新的UV（虹膜边缘UV长度为0.5，中心依然为原点）方便之后的计算。
float2 sUV = i.uv - float2(0.5, 0.5);
float2 sUVIris = sUV / _IrisRadius / 2;
折射
案例中使用了简单的 视差映射
以下是一种更复杂的折射


虹膜折射效果
由于虹膜和瞳孔的部分是处于角膜下一定距离，并且房水和角膜作为介质有一定的的折射率，因此这里我们需要引入一个视差效果来给予眼球立体感。
我将所有的计算首先转换到模型空间下。这里如果将虹膜视为一个平面，（模型采用平面投影UV，不过此处为了让计算更简单一点采用表面法线和虹膜平面的交点作为原UV）我们可以得到如下的光路图：
[图片]
作者：techiz
链接：https://www.jianshu.com/p/9b7e40886ebf
虹膜散射
添加虹膜的法线贴图实现凹进去的视觉效果
散射前
[图片]
散射后
[图片]
最终结果

![image](https://github.com/junyangtong/Human/assets/135015047/98ae67fa-aadf-418f-a6da-c5eacf438e11)

三、头发渲染
关于Shader的定位，主要是处理头发混叠、高光形状、动态光影下的表现和一些头发渲染过程的性能优化的。提升表现力上限更多的是靠模型和贴图。
多层渲染
头发多pass渲染达到柔化边缘的效果
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
            #include "Hair.cginc"
            ENDCG
        }
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
            #include "Hair.cginc"
            ENDCG
        }
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
[图片]

[图片]
头发sss与透射

[图片]
实现效果（对结果影响不大）

![image](https://github.com/junyangtong/Human/assets/135015047/9883531e-8f6c-43bf-8b84-30c76686fa38)

[图片]

透射效果
[图片]
[图片]
各向异性高光
kajiya- kay模型

![image](https://github.com/junyangtong/Human/assets/135015047/29d6b971-83fd-4ecf-8b49-0f409a977fb7)


flowmap
绘制正确的flowmap，把uv横平竖直展开好很重要
flowmap painter
[图片]

[图片]
[图片]
[图片]


实现效果

[图片]

![image](https://github.com/junyangtong/Human/assets/135015047/215f562f-599c-46d4-8358-0474b0c2788e)

[图片]
参考：
https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-14-advanced-techniques-realistic-real-time-skin
皮肤渲染其他文章：
https://zhuanlan.zhihu.com/p/397037573
头发渲染文章：
https://zhuanlan.zhihu.com/p/330259306
论文：
https://www.cs.drexel.edu/~david/Classes/CS586/Papers/p271-kajiya.pdf


使用的模型比较粗糙最后效果不是很好..
